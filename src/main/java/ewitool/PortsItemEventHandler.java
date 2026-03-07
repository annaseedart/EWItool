/**
 * PortsItemEventHandler - this class is just an event handler for the
 *                         MIDI Ports menu item.
 * 
 * This file is part of EWItool.

    EWItool is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    EWItool is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with EWItool.  If not, see <http://www.gnu.org/licenses/>.
 */

/**
 * @author S.Merrony
 * 
 * v.2.0  Catch MidiUnavailableException properly
 * v.2.1+ Show device descriptions; add Auto-detect button
 */
package ewitool;

import java.util.List;
import java.util.Optional;

import javax.sound.midi.MidiDevice;
import javax.sound.midi.MidiSystem;
import javax.sound.midi.MidiUnavailableException;
import javax.sound.midi.Sequencer;
import javax.sound.midi.Synthesizer;

import javafx.application.Platform;
import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.concurrent.Task;
import javafx.event.ActionEvent;
import javafx.event.EventHandler;
import javafx.geometry.Insets;
import javafx.scene.control.Alert;
import javafx.scene.control.Alert.AlertType;
import javafx.scene.control.Button;
import javafx.scene.control.ButtonType;
import javafx.scene.control.Dialog;
import javafx.scene.control.Label;
import javafx.scene.control.ListView;
import javafx.scene.layout.GridPane;

public class PortsItemEventHandler implements EventHandler<ActionEvent> {
  
  UserPrefs userPrefs;
  MidiHandler midiHandler;
  
  PortsItemEventHandler( UserPrefs pPrefs, MidiHandler pMidiHandler ){
    userPrefs = pPrefs;
    midiHandler = pMidiHandler;
  }

  /** Format a device info entry for display: "Name  (Description)" */
  private static String formatEntry( MidiDevice.Info info ) {
    String desc = info.getDescription();
    if (desc != null && !desc.isEmpty() && !desc.equals( info.getName() )) {
      return info.getName() + "  (" + desc + ")";
    }
    return info.getName();
  }

  @Override
  public void handle( ActionEvent arg0 ) {
    
    Dialog<ButtonType> dialog = new Dialog<>();
    dialog.setTitle( "EWItool - Select MIDI Ports" );
    dialog.getDialogPane().getButtonTypes().addAll( ButtonType.CANCEL, ButtonType.OK );
    GridPane gp = new GridPane();
    gp.setHgap( 10 );
    gp.setVgap( 8 );
    gp.setPadding( new Insets( 10 ) );
    
    gp.add( new Label( "MIDI In Ports" ), 0, 0 );
    gp.add( new Label( "MIDI Out Ports" ), 1, 0 );
    
    ObservableList<String> inPorts  = FXCollections.observableArrayList();
    ObservableList<String> outPorts = FXCollections.observableArrayList();
    ListView<String> inView  = new ListView<>( inPorts );
    ListView<String> outView = new ListView<>( outPorts );
    inView.setPrefWidth( 320 );
    outView.setPrefWidth( 320 );
       
    String lastInDevice  = userPrefs.getMidiInPort();
    String lastOutDevice = userPrefs.getMidiOutPort();
    int ipIx = -1, opIx = -1;
    
    MidiDevice.Info[] infos = MidiSystem.getMidiDeviceInfo();
    for ( MidiDevice.Info info : infos ) {
      try {
        MidiDevice device = MidiSystem.getMidiDevice( info );
        if (!( device instanceof Sequencer ) && !( device instanceof Synthesizer )) {
          if (device.getMaxReceivers() != 0) {
            opIx++;
            outPorts.add( formatEntry( info ) );
            if (info.getName().equals( lastOutDevice )) {
              outView.getSelectionModel().clearAndSelect( opIx );
            }
            Debugger.log( "DEBUG - Found OUT Port: " + info.getName() + " - " + info.getDescription() );
          }
          if (device.getMaxTransmitters() != 0) {
            ipIx++;
            inPorts.add( formatEntry( info ) );
            if (info.getName().equals( lastInDevice )) {
              inView.getSelectionModel().clearAndSelect( ipIx );
            }
            Debugger.log( "DEBUG - Found IN Port: " + info.getName() + " - " + info.getDescription() );
          }
        }
      } catch (MidiUnavailableException ex) {
        ex.printStackTrace();
      }
    }
 
    gp.add( inView, 0, 1 );
    gp.add( outView, 1, 1 );

    // Auto-detect button — probes all port combinations for an EWI4000s
    Button autoDetectBtn = new Button( "Auto-detect EWI4000s" );
    autoDetectBtn.setMaxWidth( Double.MAX_VALUE );
    autoDetectBtn.setOnAction( ae -> {
      autoDetectBtn.setDisable( true );
      autoDetectBtn.setText( "Scanning…" );
      Task<Boolean> scanTask = new Task<Boolean>() {
        @Override
        protected Boolean call() {
          return midiHandler.autoDetectEWI();
        }
      };
      scanTask.setOnSucceeded( ev -> {
        boolean found = scanTask.getValue();
        if (found) {
          // Refresh the list views so the newly saved ports appear selected
          String newOut = userPrefs.getMidiOutPort();
          String newIn  = userPrefs.getMidiInPort();
          for (int i = 0; i < outPorts.size(); i++) {
            if (outPorts.get( i ).startsWith( newOut )) {
              outView.getSelectionModel().clearAndSelect( i );
              break;
            }
          }
          for (int i = 0; i < inPorts.size(); i++) {
            if (inPorts.get( i ).startsWith( newIn )) {
              inView.getSelectionModel().clearAndSelect( i );
              break;
            }
          }
          Alert ok = new Alert( AlertType.INFORMATION, "EWI4000s detected!\nIN: " + newIn + "\nOUT: " + newOut );
          ok.setTitle( "EWItool - Auto-detect" );
          ok.setHeaderText( null );
          ok.showAndWait();
        } else {
          Alert err = new Alert( AlertType.WARNING, "No EWI4000s was found on any available MIDI port.\n\nMake sure the EWI4000s is switched on and connected via USB." );
          err.setTitle( "EWItool - Auto-detect" );
          err.setHeaderText( null );
          err.showAndWait();
        }
        autoDetectBtn.setText( "Auto-detect EWI4000s" );
        autoDetectBtn.setDisable( false );
      });
      scanTask.setOnFailed( ev -> {
        autoDetectBtn.setText( "Auto-detect EWI4000s" );
        autoDetectBtn.setDisable( false );
      });
      new Thread( scanTask ).start();
    });

    gp.add( autoDetectBtn, 0, 2, 2, 1 );

    dialog.getDialogPane().setContent( gp );
    
    Optional<ButtonType> rc = dialog.showAndWait();
    
    if (rc.isPresent() && rc.get() == ButtonType.OK) {
      // The list entries have format "Name  (Description)" — extract the name part
      if (outView.getSelectionModel().getSelectedIndex() != -1) {
        String selected = outView.getSelectionModel().getSelectedItem();
        String portName = extractPortName( selected );
        userPrefs.setMidiOutPort( portName );
      }
      if (inView.getSelectionModel().getSelectedIndex() != -1) {
        String selected = inView.getSelectionModel().getSelectedItem();
        String portName = extractPortName( selected );
        userPrefs.setMidiInPort( portName );
      } 
    }
  }

  /** Reverse of formatEntry() — return just the device name portion. */
  private static String extractPortName( String entry ) {
    int parenIdx = entry.indexOf( "  (" );
    return parenIdx >= 0 ? entry.substring( 0, parenIdx ) : entry;
  }

}
