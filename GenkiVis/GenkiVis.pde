
import processing.serial.*;
import ddf.minim.*;

AudioPlayer player;
Minim minim; //audio context

Serial serialPort;
String inputString = null;
int lf = 10;    // Linefeed in ASCII

int activeThreshold = 350;
int directionThreshold = 200;

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
color pinkColor = color(226, 106, 106);
color greenColor = color(3, 166, 120);
color lightBlueColor = color(82, 179, 217);

ArrayList<PVector> sensorPositions = new ArrayList<PVector>();
int[] sensorData = new int[8];
int[] sensorDataError = new int[8];
int sensorDataAvg = 0;
PVector sensorCenterVector = new PVector(0, 0);

int[] sensorZero = new int[]{0, 0, 0, 0 ,0 ,0 ,0, 0};

SocketServer socketServer;
Calibration cal; 

// time counter
int activeBeginTime = millis();
int activeTimeThreshold = 5000;
int longBeginTime = millis();
int longTimeThreshold = 5000;
int directionBeginTime = millis();
int directionTimeThreshold = 1000;
int errorBeginTime = millis();
int errorTimeThreshold = 3000;

boolean isErrorActive = false;

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

  minim = new Minim(this);

  cal = new Calibration(); 
}

void draw()
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
          float inputValue = (float)Integer.parseInt(inStringArr[i]);
          // inputValue = cal.getCaliData(inputValue, i);
          // inputValue = inputValue*100;
          inputValue = inputValue*600/1024;
          sensorData[i] = (int)(600-inputValue);
          // set 100 ~ 600
          // int r = (int)random(100, 600);
          // sensorData[i] = r;

          // fixed data
          // sensorData[i] = i*50+200; 
        }
        // calculate average
        int maxValue = 0;
        for (int i=0; i<sensorPositions.size(); i++) {
          int data = sensorData[i] - sensorZero[i] + 300;
          sensorDataAvg = sensorDataAvg + data;
          PVector pv = sensorPositions.get(i);
          sensorCenterVector.add(PVector.mult(pv, data));

          if(data > maxValue){
            maxValue = data;
          }
        }
        sensorDataAvg = sensorDataAvg/sensorData.length;
        // println("sensorCenterVector: "+sensorCenterVector);
        // println("sensorDataAvg: "+sensorDataAvg+", max: "+maxValue);

        // setup background
        background(255, 245, 217, 1);

        // check is active
        if(isActive()) {
          background(255, 225, 219, 1);
        }
        // check has direction
        if(hasDirection()) {
          if(!isErrorActive){
            isErrorActive = true;
            errorBeginTime = millis();
          }
          else{
            int errorPassedTime = millis() - errorBeginTime;
            if(errorPassedTime > errorTimeThreshold){
              // sitting error sound
              if(errorBeginTime%3 == 0)
                player = minim.loadFile("fart1.mp3", 2048);
              else if(errorBeginTime%3 == 1)
                player = minim.loadFile("fart4.mp3", 2048);
              else
                player = minim.loadFile("fart5.mp3", 2048);

              player.setGain(100.0);
              player.play();
              errorBeginTime = millis();
            }
          }

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
              case 0:
                event = "left";
                break;
              case 4:
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
        else { // without direction
          isErrorActive = false;
        }


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
        sphere(sensorPositionRadius*(3+sensorDataAvg*3/1024));
        popMatrix();
      }   
    }
  }
}

boolean isActive()
{
  return (sensorDataAvg > activeThreshold);
}

boolean hasDirection()
{
  return (sensorCenterVector.mag() > directionThreshold);
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
    case ' ':
      for (int i=0; i < sensorZero.length; i++)
        sensorZero[i] = sensorData[i];
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

public static class Calibration{
  
  // The response curve 
  private static float[] dist = new float[]{1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 5.5, 6.0, 6.5,
    7.0, 7.5, 8.0, 8.5, 9.0, 9.5, 10.0, 10.5, 11.0, 11.5, 12.0, 12.5, 13.0};
  private static float[] val = new float[]{29.843, 32.277, 36.063, 42.84, 67.08, 261.84, 420.20, 542.93,
    625.50, 688.3, 736.22, 772.22, 804.14, 828.45, 848.9, 866.46, 880.92, 893.98, 904.99, 914.77, 923.77,
    931.36, 938.4, 944.64, 950.07};
  private static float base = 1005.74; 
  private static int LEN;

  private static int[] sensorDataBase = new int[]{911, 914, 928, 903, 897, 908, 910, 913};

  public Calibration(){
    if (dist.length == val.length)
      LEN = dist.length;
    else
      println("respone curve not match");     
  }

  private static float getCaliData(float raw, int sensorIdx){
    float offset_raw = raw + base - sensorDataBase[sensorIdx];
    int i = 0;
    while (i < LEN && offset_raw > val[i]){ i++; }

    if ( i == 0){
      return 0;
    }
    else if ( i == LEN){
      float tmp = dist[i-1] + (dist[i-1]-dist[i-2]) * (offset_raw-val[LEN-1]) / (val[i-1]-val[i-2]);
      return tmp;
    }
    else{
      float tmp = dist[i-1] + (dist[i]-dist[i-1]) * (offset_raw-val[i-1]) / (val[i]-val[i-1]);
      return tmp;
    }
  }
}
