import java.util.ArrayList;
import java.util.Collections;
import ketai.sensors.*;
import ketai.net.nfc.*;
import android.hardware.SensorManager;
import android.hardware.SensorEvent;
import android.content.Intent;
import android.os.Bundle;
import android.os.Vibrator;
import android.os.VibrationEffect;
import android.app.Activity;
import android.content.Context;

Phone curPhone;
KetaiSensor sensor;
KetaiNFC ketaiNFC;
Activity act;
Vibrator vib;
String nfcTag = "";
PVector accelerometer, gyro, rotVector;
float light = 0;
float proximity = 0;
int stage = 1;
boolean stageOnePassed = false;

private class Target
{
  int target = 0;
  int action = 0;
}

private class Phone
{
  int lightThreshold;
  float gyroThreshold;
  float hitThreshold;
  float leftRotThreshold;
  float rightRotThreshold;
  float forwardRotThreshold;
  float backRotThreshold;
  
  public Phone(int lightThreshold, float gyroThreshold, float hitThreshold, 
                float leftRotThreshold, float rightRotThreshold, float backRotThreshold, float forwardRotThreshold) 
  {
    this.lightThreshold = lightThreshold;
    this.gyroThreshold = gyroThreshold;
    this.hitThreshold = hitThreshold;
    this.leftRotThreshold = leftRotThreshold;
    this.rightRotThreshold = rightRotThreshold;
    this.forwardRotThreshold = forwardRotThreshold; 
    this.backRotThreshold = backRotThreshold;

  }
                  
}

Phone nikhilPhone = new Phone(5, 2, -4, -.23, .23, .15, -.30);
Phone ericPhone = new Phone(3, 1, 11, .13, .13, .1, .20);

int trialCount = 5; //this will be set higher for the bakeoff
int trialIndex = 0;
ArrayList<Target> targets = new ArrayList<Target>();

int startTime = 0; // time starts when the first click is captured
int finishTime = 0; //records the time of the final click
boolean userDone = false;
int countDownTimerWait = 0;

void setup() {
  //nikhilPhone = new Phone(5, 2, -4, -.23, .23, .15, -.30);
  //ericPhone = new Phone(3, .5, -4, -.13, .13, .1, -.20);
  
  trialIndex = 0;
  //curPhone = nikhilPhone;
  //size(2880, 1440); //you can change this to be fullscreen
  curPhone = ericPhone;
  size(2280, 1080);
  //frameRate(30);
  orientation(LANDSCAPE);
   
  sensor = new KetaiSensor(this);
  sensor.start();
  sensor.setSamplingRate(SensorManager.SENSOR_DELAY_FASTEST);
  accelerometer = new PVector();
  gyro = new PVector();
  rotVector = new PVector();
  
  rectMode(CENTER);
  textFont(createFont("Arial", 40)); //sets the font to Arial size 20
  textAlign(CENTER);
  noStroke(); //no stroke

  for (int i=0; i<trialCount; i++)  //don't change this!
  {
    Target t = new Target();
    t.target = ((int)random(1000))%4;
    t.action = ((int)random(1000))%2;
    targets.add(t);
    //println("created target with " + t.target + "," + t.action);
  }
  
  act = this.getActivity();
  vib = (Vibrator) act.getSystemService(Context.VIBRATOR_SERVICE);
  Collections.shuffle(targets); // randomize the order of the button;
}

void draw() {
  int index = trialIndex;

  //uncomment line below to see if sensors are updating
  //println("light val: " + light +", cursor accel vals: " + cursorX +"/" + cursorY);
  background(80); //background is light grey
  
  if(countDownTimerWait > 0)
  {
    countDownTimerWait--;
    println("%%%%%%%%%%% countdown timer changing - " + countDownTimerWait);
  }
    
  if (startTime == 0)
    startTime = millis();

  if (index>=targets.size() && !userDone)
  {
    userDone=true;
    finishTime = millis();
  }

  if (userDone)
  {
    text("User completed " + trialCount + " trials", width/2, 50);
    text("User took " + nfc((finishTime-startTime)/1000f/trialCount, 2) + " sec per target", width/2, 150);
    return;
  }

//code to draw four target dots in a grid


  fill(255);//white
  text("Trial " + (index+1) + " of " +trialCount, width/2, 50);
  //text("Target #" + (targets.get(index).target), width/2, 100);

  
  //debug output only, slows down rendering
  /*text("light:" + int(light) + "\n"
        + "stage: " + stage + "\n"
        + "proximity: " + int(proximity) + "\n"
        + "accelX: " + nfp(accelerometer.x, 1, 2) + "\n" 
        + "accelY: " + nfp(accelerometer.y, 1, 2) + "\n" 
        + "------------accelZ: " + nfp(accelerometer.z, 1, 2) + "\n"
        + "gyroX: " + nfp(gyro.x, 1, 2) + "\n" 
        + "gyroY: " + nfp(gyro.y, 1, 2) + "\n" 
        + "gryoZ: " + nfp(gyro.z, 1, 2) + "\n"
        + "rotX: " + nfp(rotVector.x, 1, 2) + "\n" 
        + "rotY: " + nfp(rotVector.y, 1, 2) + "\n" 
        + "rotZ: " + nfp(rotVector.z, 1, 2) + "\n"
        + "nfcTag: " + nfcTag, width/4, 100);*/
  //text("z-axis accel: " + nf(accel,0,1), width/2, height-50); //use this to check z output!
  //text("touching target #" + hitTest(), width/2, height-150); //use this to check z output!
  
  Target curTarget = targets.get(trialIndex);
  if(stage == 1) {
    stroke(255);
    if(curTarget.target == 0) {
        text("TILT FORWARD", width/2, height/2);
        drawArrow(width/2,100, 100, 270);
    } 
    else if(curTarget.target == 1) {
        text("TILT RIGHT", width/2, height/2);
        drawArrow(width-100, height/2, 100, 0);
    } 
    else if(curTarget.target == 2) {
        text("TILT BACK", width/2, height/2);
        drawArrow(width/2, height-100, 100, 90);
    } 
    else {
        text("TILT LEFT", width/2, height/2);
        drawArrow(100, height/2, 100, 180);
    }
  }
  else if(stage == 2) {
    if(curTarget.action == 1)// && light > curPhone.lightThreshold)
      text("COVER LIGHT SENSOR AND SHAKE DOWNWARDS", width/2, height/2);
    else if(curTarget.action == 0)// && light < curPhone.lightThreshold)
      text("UNCOVER LIGHT SENSOR AND SHAKE DOWNWARDS", width/2, height/2);
    //else {
    //  text("HIT", width/2, height /2);
    //}
  }
}

void drawArrow(int cx, int cy, int len, float angle){
  pushMatrix();
  translate(cx, cy);
  rotate(radians(angle));
  line(0,0,len, 0);
  line(len, 0, len - 8, -8);
  line(len, 0, len - 8, 8);
  popMatrix();
}

void stageOneUpdate() {
  if(stage == 1 && countDownTimerWait == 0 && !stageOnePassed) {
    Target curTarget = targets.get(trialIndex); 
    if(curTarget == null)
      return;  
    if(gyro.y > curPhone.gyroThreshold && rotVector.y > curPhone.forwardRotThreshold) {
      stageOnePassed = curTarget.target == 0;
      stage = 2;
      countDownTimerWait = 10;
    } 
    else if(gyro.x > curPhone.gyroThreshold && rotVector.x > curPhone.rightRotThreshold) {
      stageOnePassed = curTarget.target == 1;
      stage = 2;
      countDownTimerWait = 10;
    }
    else if(gyro.y > -curPhone.gyroThreshold && rotVector.y < curPhone.backRotThreshold) {
      stageOnePassed = curTarget.target == 2;
      stage = 2;
      countDownTimerWait = 10;
    }
    else if(gyro.x > -curPhone.gyroThreshold && rotVector.x < curPhone.leftRotThreshold) {
      stageOnePassed = curTarget.target == 3;
      println("StageOnePassed = " + stageOnePassed + " curTarget: " + (curTarget.target == 3));
      stage = 2;
      countDownTimerWait = 10;
    }
    if(!stageOnePassed) { 
      stage = 1;
      countDownTimerWait = 10;
    }
    println("StageOnePassed = " + stageOnePassed + " curTarget: " + (curTarget.target == 3));  
  }
}

void stageTwoUpdate() {
  if(stage == 2 && countDownTimerWait == 0) {
    Target curTarget = targets.get(trialIndex);
    if(curTarget == null)
      return;
      
    if(curTarget.action == 1 && light > curPhone.lightThreshold) 
      vib.vibrate(VibrationEffect.createOneShot(100, VibrationEffect.DEFAULT_AMPLITUDE)); 
    
    //println("The Z accelerometer is - " + accelerometer.z + " Hit threshold - " + curPhone.hitThreshold);
    if(accelerometer.z > curPhone.hitThreshold) {
      println("currTarget.action: " + curTarget.action + " == 0?\n" + light + " > " + curPhone.lightThreshold + "? OR");
      println("currTarget.action: " + curTarget.action + " == 1?\n" + light + " < " + curPhone.lightThreshold + "?");
      if(stageOnePassed) {
        if((curTarget.action == 0 && light > curPhone.lightThreshold) || (curTarget.action == 1 && light < curPhone.lightThreshold)) {
          trialIndex++;
          println("The Z accelerometer is - " + accelerometer.z + " Hit threshold - " + curPhone.hitThreshold);

          //stageOnePassed = false;
          println("Done with stage 2, trial index increased to " + trialIndex);
          stage = 1;
          countDownTimerWait = 10;
        }
      } 
      //else {
      //   trialIndex = max(trialIndex - 1, 0);
      //} 
      countDownTimerWait = 10;
      stage = 1;
    }
  }
}

//use gyro (rotation) to update angle
void onGyroscopeEvent(float x, float y, float z)
{
  if(stage == 1){
    gyro.set(x, y, z);
    stageOneUpdate();
  }
}

void onLightEvent(float v) //this just updates the light value
{
  light = v;
  stageTwoUpdate();
}

void onProximityEvent(float v) 
{
  proximity = v;
}

void onAccelerometerEvent(float x, float y, float z)
{
  accelerometer.set(x, y, z);
  stageTwoUpdate();
}

void onRotationVectorEvent(float x, float y, float z)
{
  rotVector.set(x, y, z);
  stageOneUpdate();
}

public void onCreate(Bundle savedInstanceState) { 
  super.onCreate(savedInstanceState);
  ketaiNFC = new KetaiNFC(this);
}

public void onNewIntent(Intent intent) { 
  if (ketaiNFC != null)
    ketaiNFC.handleIntent(intent);
}
