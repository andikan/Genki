
import processing.serial.*;

int screenWidth = 800;
int screenhHeight = screenWidth;

int cushionWidth = 550;
int cushionHeight = cushionWidth;
int cushionDepth = 50;

int sensorPositionRadius = 25;
int sensorDataWidth = 20;

color cushionColor = color(27, 163, 156);
color redColor = color(214, 69, 65);

ArrayList<PVector> sensorPositions = new ArrayList<PVector>();
int[] sensorData = new int[8];
PVector centerVector = new PVector(0, 0);

SocketServer socketServer;

void setup()
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

void draw()
{
  background(255, 255, 255, 1);

  // float fov = PI/3.0;
  // float cameraZ = (height/2.0) / tan(fov/2.0);
  // perspective(fov, float(width)/float(height), 
  //           cameraZ/10.0, cameraZ*10.0);
  camera(width/2.0+80, height/2.0-80, (height/2.0) / tan(PI*30.0 / 180.0), width/2.0, height/2.0, 0, 0, 1, 0);

  // setup light
  lights();
  pointLight(255, 255, 255, 0, 0, -1);


  // draw cushion
  pushMatrix();
  translate(width/2, height*8.1/10, -50);
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
    PVector position = PVector.mult(sensorPositions.get(i), cushionWidth*3.8/10);
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
    PVector position = PVector.mult(sensorPositions.get(i), cushionWidth*3.8/10);
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
String event;
void keyPressed()
{
 
  switch (keyCode) {
    case UP:
      event = "up";
      socketServer.sendToAll( event );
      // do something if the key pressed was 'r'
      break;  
    case RIGHT:
      event = "right";
      socketServer.sendToAll( event );
      break;
    case DOWN:
      event = "down";
      socketServer.sendToAll( event );
      break;
    case LEFT:
      event = "left";
      socketServer.sendToAll( event );
      break;
    default:  
      break;
  }
 
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
