// celt_frame.mbt
//
// CELT 帧级解码主流程（RFC 6716 §4.3 频域段）。
//
// 对应参考实现 celt_celt_decoder.c 的 celt_decode_frame：把已完成的各
// 部件按规范顺序串起来——帧间能量状态预处理 → 帧首四符号 → 粗能量 →
// TF → spread → band boost/trim → 预算与反塌缩预留 → 比特分配 →
// 细能量 → 形状解码（quant_all_bands）→ 反塌缩标志 → 收尾细能量 →
// 反塌缩 → 静音置位 → 反归一化 → 帧间状态轮换。
//
// 范围（与实现的注释一致）：CELT-only、单声道、无损解码路径。
//   - loss_duration 安全衰减块（参考实现 1387–1415 行）只在丢包恢复期
//     生效，本流程无丢包输入，恒不触发；
//   - backgroundLogE 只被丢包隐藏（PLC）读取，正常解码不写不读，省略；
//   - 参考实现的 `st->end`/`effEBands` 在 48 kHz 模式下都等于 21，
//     effEnd 与 end 恒同，denorm 直接用 end；
//   - 静音置位（old_e = -28）按参考实现保留：帧首静音位在本流程可达
//     （首符号 tell==1，p≈2^-15，金标有定向用例），静音帧的后续符号
//     由各部件自身的 tell 门控自然跳过；
//   - 时域段（IMDCT、post-filter、de-emphasis）在 celt_synthesis.mbt，
//     由 celt_decode_frame_audio 接在本流程的 freq 输出之后。
//
// 帧间状态（对应 CELT 解码器 struct 的跨帧字段）：
//   - old_e：42 = 2*nbEBands。[0..21) 当前帧能量；[21..42) 上一帧
//     拷贝，供入口 MAXG 保护（静音帧只写前半）与 old_log_e 轮换；
//   - old_log_e/old_log_e2：42，反塌缩的 prev 槽位会读到后半；
//   - rng：跨帧 LCG 种子——初始化为 0，帧末被 `dec.rng`（本帧熵解码
//     器终值）覆盖，即参考实现的 `st->rng = dec->rng`。

///|
/// 跨帧解码状态。初始值为全 0（对应参考实现的 memset 清零）。
pub struct CeltDecoderState {
  /// oldBandE（42 = 2*nbEBands，后半为上一帧拷贝）
  old_e : Array[Double]
  /// oldLogE（42，反塌缩读到后半槽位）
  old_log_e : Array[Double]
  /// oldLogE2（42）
  old_log_e2 : Array[Double]
  /// st->rng：帧首为上一帧熵解码器终值
  mut rng : Int64
}

///|
/// 全零初始状态（rng = 0）。
pub fn CeltDecoderState::new() -> CeltDecoderState {
  CeltDecoderState::{
    old_e: Array::make(42, 0.0),
    old_log_e: Array::make(42, 0.0),
    old_log_e2: Array::make(42, 0.0),
    rng: 0L,
  }
}

///|
/// 一帧的频域解码结果。
pub struct CeltFrameResult {
  /// 帧首四符号（静音/后滤波/瞬态/帧内）
  header : CeltFrameHeader
  /// 归一化频谱 X（长度 120*m，反塌缩就地修改后的值）
  spectrum : Array[Double]
  /// 反归一化频谱（长度 120*m，IMDCT 的输入）
  freq : Array[Double]
  /// 每带 collapse mask（1 = 未塌缩）
  collapse_masks : Array[Int]
  /// quant_all_bands 线程化后的 LCG 种子（反塌缩的输入值）
  seed : Int64
}

///|
/// 解一帧的频域部分。`dec` 是按本帧载荷初始化的范围解码器，
/// `frame_bytes` 是载荷字节数（≥2，与参考实现一致：len≤1 走 PLC，
/// 不在本流程），`start`/`end` 是编码带窗（CELT-only 单声道为 0/21），
/// `lm` 是帧长索引。`state` 跨帧就地更新。
///
/// 顺序与参考实现逐段对齐；返回值含全部可供金标比对的中间产物。
pub fn celt_decode_frame(
  dec : RangeDecoder,
  frame_bytes : Int,
  start : Int,
  end : Int,
  lm : Int,
  state : CeltDecoderState,
) -> CeltFrameResult {
  let m = 1 << lm
  let nb = CEL_NB_EBANDS

  // 参考实现解码入口的 MAXG 保护（C==1）：前半与上一帧拷贝取 max，
  // 让静音帧写下的 -28 在下一帧被后半的正常值救回。正常路径下入口处
  // 两半相等（每帧帧末都会拷贝），此步为恒等操作。
  for i in 0..<nb {
    if state.old_e[nb + i] > state.old_e[i] {
      state.old_e[i] = state.old_e[nb + i]
    }
  }

  let header = celt_decode_frame_header(dec, frame_bytes, start, lm)

  cel_unquant_coarse_energy(dec, state.old_e, start, end, header.intra, lm)
  let tf_res = celt_decode_tf(
    dec,
    start,
    end,
    header.is_transient,
    lm,
    frame_bytes,
  )
  let spread = celt_decode_spread(dec, frame_bytes)

  let cap = celt_init_caps(lm, 1)
  let flags = celt_decode_alloc_flags(dec, start, end, cap, frame_bytes, lm)

  // 反塌缩预留：瞬态、LM≥2 且预算充足才读 1 个 raw bit 的空间
  let mut bits = celt_alloc_total(frame_bytes, dec)
  let mut anti_rsv = 0
  if header.is_transient && lm >= 2 && bits >= (lm + 2) << CEL_BITRES {
    anti_rsv = 1 << CEL_BITRES
  }
  bits = bits - anti_rsv

  let alloc = celt_compute_allocation(
    dec,
    start,
    end,
    flags.offsets,
    cap,
    flags.alloc_trim,
    bits,
    lm,
  )
  cel_unquant_fine_energy(dec, state.old_e, start, end, alloc.ebits)

  let x : Array[Double] = Array::make(120 * m, 0.0)
  let masks : Array[Int] = Array::make(nb, 0)
  // 形状解码的预算按参考实现是整帧 1/8 bit 减预留（不扣已消费位数——
  // 消费记账由 balance/budget 机制负责），seed 来自跨帧状态。
  let seed = celt_quant_all_bands(
    dec,
    x,
    start,
    end,
    lm,
    header.is_transient,
    alloc.pulses,
    tf_res,
    alloc.coded_bands,
    frame_bytes * (8 << CEL_BITRES) - anti_rsv,
    alloc.balance,
    spread,
    state.rng,
    masks,
  )

  let mut anti_on = 0
  if anti_rsv > 0 {
    anti_on = celt_decode_anti_collapse_flag(dec, anti_rsv)
  }
  cel_unquant_energy_finalise(
    dec,
    state.old_e,
    start,
    end,
    alloc.ebits,
    alloc.fine_priority,
    frame_bytes * 8 - dec.tell(),
  )
  if anti_on != 0 {
    celt_anti_collapse(
      x,
      masks,
      lm,
      start,
      end,
      state.old_e,
      state.old_log_e,
      state.old_log_e2,
      alloc.pulses,
      seed,
    )
  }

  // 静音帧：当前能量置 -28（只写前半，后半留给入口 MAXG 保护）
  if header.silence {
    for i in 0..<nb {
      state.old_e[i] = -28.0
    }
  }

  let freq = celt_denormalise(x, state.old_e, start, end, m, header.silence)

  // ---- 帧间状态轮换（参考实现 1587–1617 行）----
  // C==1：当前帧能量存入后半，作为下一帧入口 MAXG 的保护源。
  for i in 0..<nb {
    state.old_e[nb + i] = state.old_e[i]
  }
  if !header.is_transient {
    // 长块：两代对数能量整体下移一代（42 项，后半随之镜像）
    for i in 0..<42 {
      state.old_log_e2[i] = state.old_log_e[i]
      state.old_log_e[i] = state.old_e[i]
    }
  } else {
    // 瞬态：取历史最小值（42 项，与参考实现同宽）
    for i in 0..<42 {
      if state.old_log_e[i] > state.old_e[i] {
        state.old_log_e[i] = state.old_e[i]
      }
    }
  }
  // st->rng = dec->rng：下一帧的 LCG 种子是本帧熵解码器终值
  state.rng = dec.rng

  CeltFrameResult::{ header, spectrum: x, freq, collapse_masks: masks, seed, }
}
