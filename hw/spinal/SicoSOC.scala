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
}


object GenerateSOC extends App {
    spinalConfig.generateVerilog(SicoSOC(None))
}