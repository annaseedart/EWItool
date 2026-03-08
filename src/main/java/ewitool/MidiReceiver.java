/**
 * This file is part of EWItool.
 *
 *  EWItool is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  EWItool is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with EWItool.  If not, see <http://www.gnu.org/licenses/>.
 */

package ewitool;

import javax.sound.midi.MidiMessage;
import javax.sound.midi.Receiver;
import javax.sound.midi.SysexMessage;

import ewitool.SendMsg.MidiMsgType;
import javafx.application.Platform;

public class MidiReceiver implements Receiver {

  SharedData sharedData;

  /**
   * @param pSharedData
   */
  public MidiReceiver( SharedData pSharedData ) {
    sharedData = pSharedData;
  }

  @Override
  public synchronized void send( MidiMessage message, long timeStamp ) {
    
    // we are currently only interested in SysEx messages from the EWI
    // Unfortunately the structure of the SysEx messages is not consistent - we 
    // have to examine the first few bytes...

    if (message instanceof SysexMessage) {
      byte[] messageBytes = ((SysexMessage) message).getData();
      
      if (sharedData.getMidiMonitoring()) {
        MidiMonitorMessage monMsg = new MidiMonitorMessage();
        monMsg.direction = MidiMonitorMessage.MidiDirection.RECEIVED;
        monMsg.type = MidiMsgType.SYSEX;
        monMsg.bytes = ((SysexMessage) message).getData();
        sharedData.monitorQ.add( monMsg );
      }

      if (messageBytes[0] == MidiHandler.MIDI_SYSEX_AKAI_ID && 
          messageBytes[1] == MidiHandler.MIDI_SYSEX_AKAI_EWI4K
         ) { // PATCH or QuickPC

        if (messageBytes[3] == MidiHandler.MIDI_PRESET_DUMP) {
          // Some MIDI drivers include the trailing 0xF7 in getData(); strip it for length check
          int patchDataLen = messageBytes.length;
          if (patchDataLen > 0 && messageBytes[patchDataLen - 1] == MidiHandler.MIDI_SYSEX_TRAILER) {
            patchDataLen--;
          }
          // patchBlob is EWI_SYSEX_PRESET_DUMP_LEN bytes: F0 + (EWI_SYSEX_PRESET_DUMP_LEN-2) data bytes + F7
          if (patchDataLen != (MidiHandler.EWI_SYSEX_PRESET_DUMP_LEN - 2)) {
            System.err.println( "Error - Invalid preset dump SysEx received from EWI (" + messageBytes.length + " bytes)" );
            return;
          }
          // PATCH...
          EWI4000sPatch thisPatch = new EWI4000sPatch();
          thisPatch.patchBlob[0] = (byte) 0xf0;
          for (int b = 0; b < patchDataLen; b++) thisPatch.patchBlob[b+1] = messageBytes[b];
          thisPatch.patchBlob[MidiHandler.EWI_SYSEX_PRESET_DUMP_LEN - 1] = (byte) 0xf7;
          thisPatch.decodeBlob();
          // Accept patches regardless of the SysEx channel byte (may be 0x00 or 0x7F
          // depending on firmware version and how the request was issued)
          int thisPatchNum = thisPatch.internalPatchNum;   
          if (thisPatchNum < 0 || thisPatchNum >= EWI4000sPatch.EWI_NUM_PATCHES) {
            System.err.println( "Error - Invalid patch number (" + thisPatchNum + ") received from EWI");
          } else {
            // adjust thisPatchNum to be displayed version of the patch number
            if (thisPatchNum == 99)
              thisPatchNum = 0;
            else
              thisPatchNum++;
            sharedData.ewiPatchList[thisPatchNum] = thisPatch ;
            if (thisPatchNum == 99) sharedData.setLastPatchLoaded( thisPatchNum );
            sharedData.patchQ.add( thisPatchNum );
            Debugger.log( "DEBUG - MidiReceiver: Patch number: " + thisPatchNum + " received" );
          }
          return;
        }

        if (messageBytes[3] == MidiHandler.MIDI_QUICKPC_DUMP) {
          // Strip trailing F7 if present before length check
          int qpcDataLen = messageBytes.length;
          if (qpcDataLen > 0 && messageBytes[qpcDataLen - 1] == MidiHandler.MIDI_SYSEX_TRAILER) {
            qpcDataLen--;
          }
          if (qpcDataLen != (MidiHandler.EWI_SYSEX_QUICKPC_DUMP_LEN - 2)) {
            System.err.println( "Error - Invalid QuickPC dump SysEx received from EWI (" + messageBytes.length + " bytes)" );
            return;
          }
          // QUICKPC...
          for (int qpc = 0; qpc < MidiHandler.EWI_NUM_QUICKPCS; qpc++) 
            sharedData.quickPCs[qpc] = messageBytes[qpc + 5];
          sharedData.loadedQuickPCs = true;
          Debugger.log( "DEBUG - MidiReceiver: " + sharedData.quickPCs.length + " Quick PCs received" );
          return;
        }
      }

      if (messageBytes[0] == MidiHandler.MIDI_SYSEX_NONREALTIME &&
          messageBytes.length >= 4 &&
          messageBytes[2] == MidiHandler.MIDI_SYSEX_GEN_INFO &&
          messageBytes[3] == MidiHandler.MIDI_SYSEX_ID) { // DEVICE ID REPLY
        // Some MIDI drivers include the trailing 0xF7 in getData(); normalise before
        // checking the length so detection works regardless of driver behaviour.
        int idLen = messageBytes.length;
        if (idLen > 0 && messageBytes[idLen - 1] == MidiHandler.MIDI_SYSEX_TRAILER) {
          idLen--;
        }
        // Accept both the original EWI4000s non-standard format (14 bytes, firmware <= 2.3)
        // and the standard MIDI Device Identity Reply format (13 bytes, firmware 2.4+).
        // Old format:      F0 7E ch 06 02 47 64 <8 bytes> F7   => idLen==14, EWI4K at [5]
        // Standard format: F0 7E ch 06 02 47 00 64 00 01 <4 ver bytes> F7 => idLen==13, EWI4K at [6]
        if (idLen != (MidiHandler.EWI_SYSEX_ID_RESPONSE_LEN - 1) &&
            idLen != (MidiHandler.EWI_SYSEX_ID_RESPONSE_LEN - 2)) {
          Debugger.log( "DEBUG - MidiReceiver: Device ID response wrong length: " + idLen );
          sharedData.deviceIdQ.add( SharedData.DeviceIdResponse.WRONG_LENGTH );
          return;
        }
        if (messageBytes[4] != MidiHandler.MIDI_SYSEX_AKAI_ID) {
          Debugger.log( "DEBUG - MidiReceiver: Device ID response is not Akai (byte[4]=0x" + Integer.toHexString(messageBytes[4] & 0xFF) + ")" );
          sharedData.deviceIdQ.add( SharedData.DeviceIdResponse.NOT_AKAI );
          return;
        }
        // Check for EWI4000s ID (0x64):
        //   Old firmware (<= 2.3) non-standard format: 0x64 at byte[5]
        //   Firmware 2.4+ standard MIDI format: 0x00 family-LSB at byte[5], 0x64 family-MSB at byte[6]
        boolean isEwi4000s = (messageBytes[5] == MidiHandler.MIDI_SYSEX_AKAI_EWI4K)
            || (idLen >= 7 && messageBytes[5] == 0x00 && messageBytes[6] == MidiHandler.MIDI_SYSEX_AKAI_EWI4K);
        if (!isEwi4000s) {
          Debugger.log( "DEBUG - MidiReceiver: Device ID response is not EWI4000s (byte[5]=0x"
              + Integer.toHexString(messageBytes[5] & 0xFF)
              + (idLen >= 7 ? " byte[6]=0x" + Integer.toHexString(messageBytes[6] & 0xFF) : "") + ")" );
          sharedData.deviceIdQ.add( SharedData.DeviceIdResponse.NOT_EWI4000S );
          return;
        }
        // Log firmware version if available (standard MIDI format puts version at bytes [9..12])
        if (idLen >= 13 && messageBytes[5] == 0x00 && messageBytes[6] == MidiHandler.MIDI_SYSEX_AKAI_EWI4K) {
          Debugger.log( "DEBUG - MidiReceiver: EWI4000s firmware version: "
              + (messageBytes[9] & 0xFF) + "." + (messageBytes[10] & 0xFF)
              + "." + (messageBytes[11] & 0xFF) + "." + (messageBytes[12] & 0xFF) );
        }
        Debugger.log( "DEBUG - MidiReceiver got correct EWI4000s Device ID" );
        sharedData.deviceIdQ.add( SharedData.DeviceIdResponse.IS_EWI4000S);
        // must use runLater as not on GUI thread here...
        Platform.runLater( () -> {
          sharedData.setEwiAttached( true );
        } );
        return;
      }

      Debugger.log( "DEBUG - MidiReceiver: Unrecognised SysEx (length=" + messageBytes.length + 
                    ") starting: 0x" + Integer.toHexString(messageBytes[0] & 0xFF) +
                    " 0x" + Integer.toHexString(messageBytes[1] & 0xFF) +
                    " 0x" + Integer.toHexString(messageBytes[2] & 0xFF) );
    }
  }

  @Override
  public void close() {

  }

}
