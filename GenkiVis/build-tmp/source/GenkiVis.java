import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import processing.serial.*; 

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

int sensorPositionRadius = 30;
int sensorDataWidth = 20;

int cushionColor = color(27, 163, 156);

ArrayList<PVector> sensorPositions = new ArrayList<PVector>();
int[] sensorData = new int[8];

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
    sensorData[i] = i*100+200;
  }

}

public void draw()
{
  background(255, 255, 255, 1);

  // setup light
  lights();
  pointLight(255, 255, 255, 0, 0, -1);


  // draw cushion
  pushMatrix();
  translate(width/2, height*4/5, -50);
  rotateX(PI/2);
  noStroke();
  fill(cushionColor);
  box(cushionWidth, cushionHeight, cushionDepth);
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
    translate(width/2+position.x, height*4/5-sensorPositionRadius/3, -50+sensorPositionRadius+position.y);
    rotateX(PI/2);
    rotateZ(PI/4);
    // rotateZ(radians(frameCount));
    noStroke();
    fill(244, 179, 80);
    box(sensorDataWidth, sensorDataWidth, sensorData[i]);
    popMatrix();
  }

  // pushMatrix();
  // PVector position2 = PVector.mult(sensorPositions.get(2), cushionWidth*3.8/10);
  // translate(width/2+position2.x, height*4/5-sensorPositionRadius/3-200, -50+sensorPositionRadius+position2.y);
  // rotateX(PI/2);
  // rotateZ(radians(frameCount));
  // noStroke();
  // fill(82, 179, 217);
  // box(sensorDataWidth, sensorDataWidth, 300);
  // popMatrix();
  // for (int i = 0; i < sensorData.size(); i++) {
  //   pushMatrix();
  //   PVector position = PVector.mult(sensorPositions.get(i), cushionWidth*3.8/10);
  //   translate(width/2+position.x, height*4/5-sensorPositionRadius/3, -50+sensorPositionRadius+position.y);
  //   rotateX(PI*3/7);
  //   noStroke();
  //   fill(171, 183, 183);
  //   box(sensorDataWidth, sensorDataWidth, sensorData.get(i));
  //   popMatrix();
  // }
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
