import spinal.core._
import spinal.lib._


case class SicoConfig(
    val width: Int
) {
    def dtype() = UInt(width bits)
    def reg() = Reg(dtype()) init(0)
}


case class SicoBusCmd(cfg: SicoConfig) extends Bundle {
    import cfg._
    
    val addr  = dtype()
    val data  = dtype()
    val write = Bool()
}


case class SicoBusRsp(cfg: SicoConfig) extends Bundle with IMasterSlave {
    import cfg._

    val data  = dtype()

    def asMaster(): Unit = {
        out(data)
    }
}

case class SicoBus(cfg: SicoConfig) extends Bundle with IMasterSlave {
    val cmd = Stream(SicoBusCmd(cfg))
    val rsp = SicoBusRsp(cfg)

    def asMaster(): Unit = {
        master(cmd)
        slave(rsp)
    }
}


case class Sico(cfg: SicoConfig) extends Component {
    import cfg._


    val io = new Bundle {
        val bus = master(SicoBus(cfg))
    }
    import io._


    val regs = new Area {
        val a  = reg()
        val b  = reg()
        val c  = reg()
        val ip = reg()
    }


    bus.cmd.addr := 0
    bus.cmd.data := 0
    bus.cmd.write := False
    bus.cmd.valid := False


    val t0 = reg()
    val t1 = reg()


    val sub = t0 - t1
    val br  = t0 <= t1


    val state   = Reg(UInt(5 bits)) init(0)
    val advance = False

    var stateID = 0
    def nextStateID(): Int = {
        var id = stateID
        stateID += 1
        return id
    }

    switch(state) {
        def nextState(body: => Unit) = is(nextStateID())(body)

        def defFetchState(src: UInt, reg: UInt, incIP: Boolean = true) {
            nextState {
                bus.cmd.addr  := src
                bus.cmd.valid := True

                when(bus.cmd.fire) {
                    reg := bus.rsp.data
                    if(incIP) regs.ip := regs.ip + 1
                    advance := True
                }
            }
            nextState {
                advance := True
            }
        }

        defFetchState(regs.ip, regs.a)
        defFetchState(regs.ip, regs.b)
        defFetchState(regs.ip, regs.c)
        defFetchState(regs.a, t0, false)
        defFetchState(regs.b, t1, false)
    
        nextState {
            bus.cmd.addr := regs.a
            bus.cmd.data := sub
            bus.cmd.write := True
            bus.cmd.valid := True

            when(bus.cmd.fire) {
                when(br) {
                    regs.ip := regs.c
                }
                advance := True
            }
        }
        nextState {
            advance := True
        }
    }

    when(advance) {
        when(state === stateID-1) {
            state := 0
        } otherwise {
            state := state + 1
        }
    }
}