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




int screenWidth = 800;
int screenhHeight = screenWidth;

int cushionWidth = 550;
int cushionHeight = cushionWidth;
int cushionDepth = 50;

int sensorPositionRadius = 25;
int sensorDataWidth = 20;

int cushionColor = color(27, 163, 156);
int redColor = color(214, 69, 65);

ArrayList<PVector> sensorPositions = new ArrayList<PVector>();
int[] sensorData = new int[8];
int sensorDataAvg;
PVector centerVector = new PVector(0, 0);

SocketServer socketServer;

public void setup()
{
  size(screenWidth, screenhHeight, OPENGL);
  background(255, 255, 255, 1);

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

  for(int i=0; i<sensorData.length; i++) {
    sensorData[i] = i*50+200;
  }

  

  new ServerThread().start();
}

public void draw()
{
  background(238, 238, 238, 1);

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
  translate(width/2, height*4/5-sensorPositionRadius/3-10, -50+sensorPositionRadius);
  rotateX(PI/2);
  noStroke();
  fill(redColor);
  sphereDetail(30); // standard
  sphere(sensorPositionRadius);
  popMatrix();

  // draw sensor positions
  for (int i = 0; i < sensorPositions.size(); i++) {
    pushMatrix();
    PVector position = PVector.mult(sensorPositions.get(i), cushionWidth*3.8f/10);
    translate(width/2+position.x, height*4/5-sensorPositionRadius/3, -50+sensorPositionRadius+position.y);
    rotateX(PI/2);
    noStroke();
    fill(82, 179, 217);
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
}

public void keyPressed()
{
  String event = new String();
  switch (keyCode) {
    case UP:
      event = "up";
      emitEvent(event);
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
