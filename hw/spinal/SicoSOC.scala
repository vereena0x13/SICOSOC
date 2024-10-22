import scala.collection.mutable.ArrayBuffer
import scala.math

import spinal.lib._
import spinal.core._
import spinal.core.sim._

import Util._


case class SicoSOC(initial_memory: Option[Array[Short]]) extends Component {
    val io = new Bundle {
        val uart = new UartBus
    }
    import io._


    uart.wdata := 0
    uart.wr    := False
    uart.rd    := False


    val cfg = SicoConfig(
        width = 16
    )
    val sico = Sico(cfg)
    import sico.io._

    
    val ramSize = math.pow(2, cfg.width).toInt
    val mem = Mem(cfg.dtype(), ramSize)
    if(initial_memory.isDefined) {
        assert(initial_memory.get.length <= ramSize)
        val arr = new ArrayBuffer[BigInt]
        arr ++= initial_memory.get.map(x => BigInt(x & 0xFFFF))
        println(arr)
        while(arr.length < ramSize) arr += BigInt(0)
        mem.initBigInt(arr, true)
    }


    bus.cmd.ready := False
    bus.rsp.data  := 0

    val is_mmio = bus.cmd.addr === 65534

    val rd = mem.readWriteSync(
        address = bus.cmd.addr,
        data    = bus.cmd.data,
        enable  = bus.cmd.valid && !is_mmio,
        write   = bus.cmd.write
    )

    val delayed_cmd_valid = RegNext(bus.cmd.valid)
    when(bus.cmd.valid) {
        when(is_mmio & bus.cmd.write) {
            // actual value = bus.cmd.addr - bus.cmd.data
            // TODO
        } elsewhen(!bus.cmd.write) {
            bus.rsp.data := rd
        }

        when(delayed_cmd_valid) {
            bus.cmd.ready := True
        }
    }
}


object GenerateSOC extends App {
    spinalConfig.generateVerilog(SicoSOC(None))
}


object SimulateSOC extends App {
    SimConfig
        .withWave
        .withConfig(spinalConfig)
        .compile {
            val code = Array[Short](
                24, 
                1, 
                23, 
                -2.toShort, 
                9, 
                6, 
                4, 
                23, 
                0, 
                72, 
                101, 
                108, 
                108, 
                111, 
                44, 
                32, 
                87, 
                111, 
                114, 
                108, 
                100, 
                33, 
                10, 
                -1.toShort, 
                15
            )
            val soc = SicoSOC(Some(code))
            
            soc.io.uart.rdata.simPublic()
            soc.io.uart.txe.simPublic()
            soc.io.uart.rxf.simPublic()
            soc.sico.io.bus.cmd.valid.simPublic()
            soc.sico.io.bus.cmd.ready.simPublic()
            soc.sico.io.bus.cmd.write.simPublic()
            soc.sico.io.bus.cmd.addr.simPublic()
            soc.sico.io.bus.cmd.data.simPublic()
            
            soc
        }
        .doSim { soc =>
            soc.io.uart.rdata #= 0
            soc.io.uart.txe   #= true
            soc.io.uart.rxf   #= true

            
            val clk = soc.clockDomain

            clk.fallingEdge()
            sleep(0)

            clk.assertReset()
            for(_ <- 0 until 10) {
                clk.clockToggle()
                sleep(1)
            }
            clk.deassertReset()
            sleep(1)


            for(i <- 0 until 1000) {
                clk.clockToggle()
                sleep(1)
                clk.clockToggle()
                sleep(1)

                if(soc.sico.io.bus.cmd.valid.toBoolean &&
                   soc.sico.io.bus.cmd.ready.toBoolean &&
                   soc.sico.io.bus.cmd.write.toBoolean &&
                    soc.sico.io.bus.cmd.addr.toInt == 65534) {
                    //val v = soc.sico.io.bus.cmd.addr.toInt - soc.sico.io.bus.cmd.data.toInt
                    //print(v.toChar)
                    println(soc.sico.io.bus.cmd.data.toInt)
                }
            }
        }
}