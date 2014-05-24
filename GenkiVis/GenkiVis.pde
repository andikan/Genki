
import processing.serial.*;

Serial serialPort;
String inputString = null;
int lf = 10;    // Linefeed in ASCII

int activeThreshold = 400;

int screenWidth = 800;
int screenhHeight = screenWidth;

int cushionWidth = 550;
int cushionHeight = cushionWidth;
int cushionDepth = 50;

int sensorPositionRadius = 25;
int sensorDataWidth = 20;

color bgColor = color(244, 179, 80, 0.5);
color cushionColor = color(27, 163, 156);
color redColor = color(214, 69, 65);
color greenColor = color(3, 166, 120);
color lightBlueColor = color(82, 179, 217);

ArrayList<PVector> sensorPositions = new ArrayList<PVector>();
int[] sensorData = new int[8];
int[] sensorDataCali = new int[8];
int sensorDataAvg = 0;
PVector sensorCenterVector = new PVector(0, 0);

SocketServer socketServer;

void setup()
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

void draw()
{
  while (serialPort.available() > 0) {
    String inString = serialPort.readStringUntil('\n');
    if (inString != null){
      String[] inStringArr = inString.split(",");

      if(inStringArr.length == 9){
        // refresh data
        sensorDataAvg = 0;
        sensorCenterVector.set(0, 0);

        // get data
        for(int i=0; i<sensorData.length; i++) {
          int inputValue = Integer.parseInt(inStringArr[i]);
          sensorData[i] = 850-inputValue;
          // set 100 ~ 600
          // int r = (int)random(100, 600);
          // sensorData[i] = r;

          // fixed data
          // sensorData[i] = i*50+200; 
        }
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
        translate(width/2, height*4/5-sensorPositionRadius/3, -50+sensorPositionRadius);
        rotateX(PI/2);
        noStroke();
        fill(210, 215, 211);
        sphereDetail(30); // standard
        sphere(sensorPositionRadius*1.5);
        popMatrix();

        // draw sensor positions
        for (int i = 0; i < sensorPositions.size(); i++) {
          pushMatrix();
          PVector position = PVector.mult(sensorPositions.get(i), cushionWidth*3.8/10);
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
        if(centerPv.mag() > cushionWidth*3.8/10){
          centerPv.normalize();
          centerPv = PVector.mult(centerPv, cushionWidth*3.8/10);
        }
        translate(width/2+centerPv.x, height*4/5-sensorPositionRadius/3, -50+sensorPositionRadius+centerPv.y);
        rotateX(PI/2);
        noStroke();
        fill(redColor);
        sphereDetail(30); // standard
        sphere(sensorPositionRadius*(3+sensorDataAvg/600));
        popMatrix();

        // pushMatrix();
        // PVector centerPv = sensorCenterVector;
        // float centerAngle = PVector.angleBetween(centerPv, sensorPositions.get(0));
        // float centerM = centerPv.magSq();

        // translate(width/2, height*4/5-sensorPositionRadius/3-20, -50+sensorPositionRadius/2-100);
        // // rotateX(radians(frameCount));
        // rotateY(-centerAngle);
        // // rotateZ(PI/2);
        // noStroke();
        // fill(244, 179, 80);
        // box(sensorDataWidth, sensorDataWidth, sensorDataAvg);
        // popMatrix();
      }
      
    }
  }
  

}

void keyPressed()
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

void emitEvent(String event)
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
