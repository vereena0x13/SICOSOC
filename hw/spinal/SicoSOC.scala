import scala.collection.mutable.ArrayBuffer
import scala.math

import spinal.core._
import spinal.core.sim._

import Util._


case class SicoSOC(initial_memory: Option[Array[Short]]) extends Component {
    val io = new Bundle {
        val uart_wdata = out(Bits(8 bits))
        val uart_rdata = in(Bits(8 bits))
	    val uart_txe   = in(Bool())
	    val uart_rxf   = in(Bool())
	    val uart_wr    = out(Bool())
	    val uart_rd    = out(Bool())
    }
    import io._


    uart_wdata := 0
    uart_wr    := False
    uart_rd    := False


    val cfg = SicoConfig(
        width = 16
    )
    val sico = Sico(cfg)
    import sico.io._

    
    val ramSize = math.pow(2, cfg.width).toInt
    val mem = Mem(SInt(cfg.width bits), ramSize)
    if(initial_memory.isDefined) {
        assert(initial_memory.get.length <= ramSize)
        val arr = new ArrayBuffer[BigInt]
        arr ++= initial_memory.get.map(x => BigInt(x))
        while(arr.length < ramSize) arr += BigInt(0)
        mem.initBigInt(arr, true)
    }


    
}


object GenerateSOC extends App {
    spinalConfig.generateVerilog(SicoSOC(None))
}