import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import processing.serial.*; 
import java.io.BufferedReader; 
import java.io.IOException; 
import java.io.InputStreamReader; 
import java.net.InetSocketAddress; 
import java.net.UnknownHostException; 
import java.util.Collection; 
import org.java_websocket.WebSocket; 
import org.java_websocket.WebSocketImpl; 
import org.java_websocket.handshake.ClientHandshake; 
import org.java_websocket.server.WebSocketServer; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class GenkiVis extends PApplet {




Serial serialPort;
String inputString = null;
int lf = 10;    // Linefeed in ASCII

int activeThreshold = 500;
int directionThreshold = 200;

int screenWidth = 800;
int screenhHeight = screenWidth;

int cushionWidth = 550;
int cushionHeight = cushionWidth;
int cushionDepth = 50;

int sensorPositionRadius = 25;
int sensorDataWidth = 20;

int bgColor = color(244, 179, 80, 0.5f);
int cushionColor = color(27, 163, 156);
int redColor = color(214, 69, 65);
int pinkColor = color(226, 106, 106);
int greenColor = color(3, 166, 120);
int lightBlueColor = color(82, 179, 217);

ArrayList<PVector> sensorPositions = new ArrayList<PVector>();
int[] sensorData = new int[8];
int[] sensorDataCali = new int[8];
int sensorDataAvg = 0;
PVector sensorCenterVector = new PVector(0, 0);

SocketServer socketServer;

String infoStr_sitting = "\u5c41\u5c41\u63a5\u89f8\u4e2d...";

// time counter
int activeBeginTime = millis();
int activeTimeThreshold = 5000;
int longBeginTime = millis();
int longTimeThreshold = 5000;
int directionBeginTime = millis();
int directionTimeThreshold = 1000;
int errorBeginTime = millis();
int errorTimeThreshold = 5000;

public void setup()
{
  size(screenWidth, screenhHeight, OPENGL);
  background(bgColor);

  sensorPositions.add(new PVector(1, 0));
  sensorPositions.add(new PVector(1, 1));
  sensorPositions.add(new PVector(0, 1));
  sensorPositions.add(new PVector(-1, 1));
  sensorPositions.add(new PVector(-1, 0));
  sensorPositions.add(new PVector(-1, -1));
  sensorPositions.add(new PVector(0, -1));
  sensorPositions.add(new PVector(1, -1));

  for (int i=0; i<sensorPositions.size(); i++) {
    sensorPositions.get(i).normalize();
  }

  println(sensorCenterVector);

  new ServerThread().start();

  // List all the available serial ports
  println(Serial.list());
  // serialPort = new Serial(this, Serial.list()[0], 9600);
  serialPort = new Serial(this, "/dev/tty.usbmodem1411", 19200);
  serialPort.clear();

  inputString = serialPort.readStringUntil(lf);
  inputString = null;
}

public void draw()
{
  while (serialPort.available() > 0) {
    String inString = serialPort.readStringUntil('\n');
    if (inString != null){
      String[] inStringArr = inString.split(",");
      // println(inStringArr);

      if(inStringArr.length == 9){
        // refresh data
        sensorDataAvg = 0;
        sensorCenterVector.set(0, 0);

        // get data
        for(int i=0; i<sensorData.length; i++) {
          int inputValue = Integer.parseInt(inStringArr[i]);
          sensorData[i] = 800-inputValue;
          // set 100 ~ 600
          // int r = (int)random(100, 600);
          // sensorData[i] = r;

          // fixed data
          // sensorData[i] = i*50+200; 
        }
        // calculate average
        int maxValue = 0;
        for (int i=0; i<sensorPositions.size(); i++) {
          int data = sensorData[i];
          sensorDataAvg = sensorDataAvg + data;
          PVector pv = sensorPositions.get(i);
          sensorCenterVector.add(PVector.mult(pv, data));

          if(data > maxValue){
            maxValue = data;
          }
        }
        sensorDataAvg = sensorDataAvg/sensorData.length;
        // println("sensorCenterVector: "+sensorCenterVector);
        println("sensorDataAvg: "+sensorDataAvg+", max: "+maxValue);

        // setup background
        background(255, 245, 217, 1);

        // check is active
        if(isActive()) {
          background(224, 130, 131, 1);
        }
        // check has direction
        if(hasDirection()) {
          int directionPassedTime = millis() - directionBeginTime;
          if(directionPassedTime > directionTimeThreshold){
            float minDirectionAngle = 100000;
            int closeVecIndex = 0;
            for (int i=0; i<sensorPositions.size(); i++) {
              PVector sensorVec = sensorPositions.get(i);
              float directionAngle = PVector.angleBetween(sensorVec, sensorCenterVector);
              if(directionAngle < minDirectionAngle) {
                minDirectionAngle = directionAngle;
                closeVecIndex = i;
              }
            }

            println("Direction: "+closeVecIndex);
            String event = new String();
            switch (closeVecIndex) {
              case 2:
                event = "up";
                break;
              case 6:
                event = "down"; 
                break;
              case 4:
                event = "left";
                break;
              case 0:
                event = "right";
                break;
              default: 
                event = "none";
                break;
            }
            if(event != "none"){
              emitEvent(event);
            }

            directionBeginTime = millis();
          }
        }


        // float fov = PI/3.0;
        // float cameraZ = (height/2.0) / tan(fov/2.0);
        // perspective(fov, float(width)/float(height), 
        //           cameraZ/10.0, cameraZ*10.0);
        camera(width/2.0f+80, height/2.0f-80, (height/2.0f) / tan(PI*30.0f / 180.0f), width/2.0f, height/2.0f, 0, 0, 1, 0);

        // setup light
        lights();
        pointLight(255, 255, 255, 0, 0, -1);

        // draw cushion
        pushMatrix();
        translate(width/2, height*8.1f/10, -50);
        rotateX(PI/2);
        noStroke();
        fill(cushionColor);
        box(cushionWidth, cushionHeight, cushionDepth);
        popMatrix();

        // draw original
        pushMatrix();
        translate(width/2, height*4/5-sensorPositionRadius/3, -50+sensorPositionRadius);
        rotateX(PI/2);
        noStroke();
        fill(210, 215, 211);
        sphereDetail(30); // standard
        sphere(sensorPositionRadius*1.5f);
        popMatrix();

        // draw sensor positions
        for (int i = 0; i < sensorPositions.size(); i++) {
          pushMatrix();
          PVector position = PVector.mult(sensorPositions.get(i), cushionWidth*3.8f/10);
          translate(width/2+position.x, height*4/5-sensorPositionRadius/3, -50+sensorPositionRadius+position.y);
          rotateX(PI/2);
          noStroke();
          fill(greenColor);
          sphereDetail(30); // standard
          sphere(sensorPositionRadius);
          popMatrix();
        }

        // draw sensor data
        for (int i = 0; i < sensorPositions.size(); i++) {
          pushMatrix();
          PVector position = PVector.mult(sensorPositions.get(i), cushionWidth*3.8f/10);
          translate(width/2+position.x, height*4/5-sensorPositionRadius/3-sensorData[i]/2, -50+sensorPositionRadius+position.y);
          rotateX(PI/2);
          rotateZ(PI/4);
          // rotateZ(radians(frameCount));
          noStroke();
          fill(244, 179, 80);
          box(sensorDataWidth, sensorDataWidth, sensorData[i]);
          popMatrix();
        }

        // // draw sensor center vector
        // pushMatrix();
        // PVector centerPv = sensorCenterVector;
        // // translate(width/2+centerPv.x, height*4/5-sensorPositionRadius/3, -50+sensorPositionRadius+centerPv.y);
        // // rotateX(PI/2);
        // noStroke();
        // fill(redColor);
        // stroke(0);
        // strokeWeight(10);
        // line(width/2, height*4/5-sensorPositionRadius/3-100, -50+sensorPositionRadius, width/2+centerPv.x, height*4/5-sensorPositionRadius/3-100, -50+sensorPositionRadius+centerPv.y);
        // popMatrix();
        pushMatrix();
        PVector centerPv = sensorCenterVector;
        if(centerPv.mag() > cushionWidth*3.8f/10){
          centerPv.normalize();
          centerPv = PVector.mult(centerPv, cushionWidth*3.8f/10);
        }
        translate(width/2+centerPv.x, height*4/5-sensorPositionRadius/3, -50+sensorPositionRadius+centerPv.y);
        rotateX(PI/2);
        noStroke();
        fill(redColor);
        sphereDetail(30); // standard
        sphere(sensorPositionRadius*(3+sensorDataAvg/600));
        popMatrix();
      }   
    }
  }
}

public boolean isActive()
{
  return (sensorDataAvg > activeThreshold);
}

public boolean hasDirection()
{
  return (sensorCenterVector.mag() > directionThreshold);
}

public void keyPressed()
{
  String event = new String();
  switch (keyCode) {
    case UP:
      event = "up";
      break;
    case DOWN:
      event = "down"; 
      break;
    case LEFT:
      event = "left";
      break;
    case RIGHT:
      event = "right";
      break;
    default:  
      break;
  }
  emitEvent(event);
}

public void emitEvent(String event)
{
  socketServer.sendToAll(event);
}


//create a separate thread for the server not to freeze/interfere with Processing's default animation thread
public class ServerThread extends Thread{
  @Override
  public void run(){
    try{
          WebSocketImpl.DEBUG = false;
          int port = 8887; // 843 flash policy port
          try {
            port = Integer.parseInt( args[ 0 ] );
          } catch ( Exception ex ) {
          }
          socketServer = new SocketServer( port );
          socketServer.start();
          System.out.println( "WS Server started on port: " + socketServer.getPort() );

          BufferedReader sysin = new BufferedReader( new InputStreamReader( System.in ) );
          while ( true ) {
            String in = sysin.readLine();
            // socketServer.sendToAll( in );
          }
        }catch(IOException e){
          e.printStackTrace();
        }  
  }
}
// web socket library













public class SocketServer extends WebSocketServer {

  public SocketServer( int port ) throws UnknownHostException {
    super( new InetSocketAddress( port ) );
  }

  public SocketServer( InetSocketAddress address ) {
    super( address );
  }

  @Override
  public void onOpen( WebSocket conn, ClientHandshake handshake ) {
    // this.sendToAll( "new connection: " + handshake.getResourceDescriptor() );
    System.out.println( conn.getRemoteSocketAddress().getAddress().getHostAddress() + " entered the room!" );
  }

  @Override
  public void onClose( WebSocket conn, int code, String reason, boolean remote ) {
    // this.sendToAll( conn + " has left the room!" );
    System.out.println( conn + " has left the room!" );
  }

  @Override
  public void onMessage( WebSocket conn, String message ) {
    // this.sendToAll( message );
    System.out.println( conn + ": " + message );
  }

  @Override
  public void onError( WebSocket conn, Exception ex ) {
    ex.printStackTrace();
    if( conn != null ) {
      // some errors like port binding failed may not be assignable to a specific websocket
    }
  }

  /**
   * Sends <var>text</var> to all currently connected WebSocket clients.
   * 
   * @param text
   *            The String to send across the network.
   * @throws InterruptedException
   *             When socket related I/O errors occur.
   */
  public void sendToAll( String text ) {
    Collection<WebSocket> con = connections();
    synchronized ( con ) {
      for( WebSocket c : con ) {
        c.send( text );
      }
    }
  }
}
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "GenkiVis" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
