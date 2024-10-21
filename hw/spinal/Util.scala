import scala.collection.mutable.ArrayBuffer
import scala.util.Using

import java.io.DataInputStream
import java.io.FileInputStream

import spinal.core._


object Util {
    def spinalConfig(): SpinalConfig = SpinalConfig(
        targetDirectory = "hw/gen",
        onlyStdLogicVectorAtTopLevelIo = true,
        defaultClockDomainFrequency = FixedFrequency(100 MHz),
        device = Device(
            vendor = "xilinx",
            family = "Artix 7"
        )
    )

    def readShorts(name: String): Array[Short] = 
        Using(new DataInputStream(new FileInputStream(name))) { din => 
            Iterator.continually(din.readShort).takeWhile(_ => din.available() > 0).toArray
        }.get
}