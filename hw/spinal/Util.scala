import scala.collection.mutable.ArrayBuffer
import scala.collection.Iterator
import scala.util.Using

import java.io.DataInputStream
import java.io.FileInputStream

import spinal.core._


object Util {
    def spinalConfig(): SpinalConfig = SpinalConfig(
        targetDirectory = "hw/gen",
        onlyStdLogicVectorAtTopLevelIo = true,
        mergeAsyncProcess = true,
        defaultClockDomainFrequency = FixedFrequency(100 MHz),
        device = Device(
            vendor = "xilinx",
            family = "Artix 7"
        )
    )

    def readShorts(name: String): Array[Short] = {
        val in = new DataInputStream(new FileInputStream(name))
        val xs = new ArrayBuffer[Short]
        while(in.available() > 0) xs += in.readShort()
        in.close()
        xs.toArray
    }
}