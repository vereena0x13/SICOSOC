import spinal.core._
import spinal.lib._


case class SicoConfig(
    val width: Int
) {
    def dtype() = SInt(width bits)
    def reg() = Reg(dtype()) init(0)
}


case class SicoBus(cfg: SicoConfig) extends Bundle {
    import cfg._
    
    val addr  = out(dtype())
    val rdata = in(dtype())
    val wdata = out(dtype())
    val write = out(Bool())
    val valid = out(Bool())
    val ready = in(Bool())
}

case class Sico(cfg: SicoConfig) extends Component {
    import cfg._


    val io = new Bundle {
        val bus = SicoBus(cfg)
    }
    import io._


    val regs = new Area {
        val a  = reg()
        val b  = reg()
        val c  = reg()
        val ip = reg()
    }

    
    bus.addr := 0
    bus.write := False
    bus.valid := False


    regs.ip := regs.ip + 1
}