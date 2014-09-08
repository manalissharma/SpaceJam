//The MIT License (MIT) - See Licence.txt for details

//Copyright (c) 2013 Mick Grierson, Matthew Yee-King, Marco Gillies


import org.jbox2d.util.nonconvex.*;
import org.jbox2d.dynamics.contacts.*;
import org.jbox2d.testbed.*;
import org.jbox2d.collision.*;
import org.jbox2d.common.*;
import org.jbox2d.dynamics.joints.*;
import org.jbox2d.p5.*;
import org.jbox2d.dynamics.*;

// audio stuff

Maxim maxim;
AudioPlayer astronautSound, wallSound, spaceSound;
AudioPlayer[] asteroidSounds; //for when they're destroyed

Physics physics; // The physics handler: we'll see more of this later

// rigid bodies for the droid and two crates
Body astronaut;
Body [] asteroids;
//Body [] asteroids2;

// the start point of the catapult 
Vec2 startPoint;

// a handler that will detect collisions
CollisionDetector detector; 

int asterSize = 60;
int astroSize = 80;

PImage asterImage, astroImage, spaceImage;

int score = 0; //score not required, add countdown timer

boolean dragging = false;

void setup() {
  size(1024,680);
  frameRate(60);


  spaceImage = loadImage("space2.jpg");
  asterImage = loadImage("aster3.png");
  astroImage = loadImage("astronaut2.png");
  imageMode(CENTER);

  //initScene();

  /**
   * Set up a physics world. This takes the following parameters:
   * 
   * parent The PApplet this physics world should use
   * gravX The x component of gravity, in meters/sec^2
   * gravY The y component of gravity, in meters/sec^2
   * screenAABBWidth The world's width, in pixels - should be significantly larger than the area you intend to use
   * screenAABBHeight The world's height, in pixels - should be significantly larger than the area you intend to use
   * borderBoxWidth The containing box's width - should be smaller than the world width, so that no object can escape
   * borderBoxHeight The containing box's height - should be smaller than the world height, so that no object can escape
   * pixelsPerMeter Pixels per physical meter
   */
  physics = new Physics(this, width, height, 0, -10, width*2, height*2, width, height, 100);
  
  // this overrides the debug render of the physics engine
  // with the method myCustomRenderer
  // comment out to use the debug renderer 
  // (currently broken in JS)
  physics.setCustomRenderingMethod(this, "myCustomRenderer");
  physics.setDensity(5.0); // lighter density since in space
    
  // set up the objects
  // Rect parameters are the top left 
  // and bottom right corners
  //posit them as floating bodies
  asteroids = new Body[7];
  asteroids[0] = physics.createRect(600, height-asterSize, 600+asterSize, 50+asterSize);
  asteroids[1] = physics.createRect(600, height-2*asterSize, 600+asterSize, 200+asterSize);
  asteroids[2] = physics.createRect(600, height-3*asterSize, 600+asterSize, height-2*asterSize);
  asteroids[3] = physics.createRect(600+1.5*asterSize, height-asterSize, 600+2.5*asterSize, height);
  asteroids[4] = physics.createRect(600+1.5*asterSize, height-2*asterSize, 600+2.5*asterSize, height-asterSize);
  asteroids[5] = physics.createRect(600+1.5*asterSize, height-3*asterSize, 600+2.5*asterSize, height-2*asterSize);
  asteroids[6] = physics.createRect(600+0.75*asterSize, height-4*asterSize, 600+1.75*asterSize, height-3*asterSize);

  startPoint = new Vec2(200, height-150);
  
  // this converts from processing screen 
  // coordinates to the coordinates used in the
  // physics engine (10 pixels to a meter by default)
  startPoint = physics.screenToWorld(startPoint);

  // circle parameters are center x,y and radius
  astronaut = physics.createCircle(width/2, -100, astroSize/2);

  // sets up the collision callbacks
  detector = new CollisionDetector (physics, this);

  //set up the sound environment
  maxim = new Maxim(this);
  astronautSound = maxim.loadFile("droid.wav");
  wallSound = maxim.loadFile("wall.wav");
  spaceSound = maxim.loadFile("space2.wav");
  
  astronautSound.setLooping(false);
  astronautSound.volume(2.0);
  wallSound.setLooping(false);
  wallSound.volume(2.0);
  spaceSound.setLooping(true);
  spaceSound.volume(1.0);
  
  
  // now an array of asteroid sounds
  asteroidSounds = new AudioPlayer[asteroids.length];
  for (int i=0;i<asteroidSounds.length;i++){
    asteroidSounds[i] = maxim.loadFile("crate2.wav");
    asteroidSounds[i].setLooping(false);
    asteroidSounds[i].volume(1);
  }

}

void draw() {
  image(spaceImage, width/2, height/2, width, height);

  // we can call the renderer here if we want
  // to run both our renderer and the debug renderer
  //myCustomRenderer(physics.getWorld());

  fill(255);
    
  //initializing timer variables
  int wait = 1;
  int ctime;
  int sec;
 
  ctime = wait*60*1000 - millis();
  sec = ctime / 1000;
  if (sec > 0){
    text("TIMER : " + sec + " seconds remaining ", 20, 20);
  }
  if (sec == 0){
   text("GAME OVER", width/2, height/2);
   physics.destroy();
  }
  
   text("Score: " + score, 20, 40); 
}

void mouseDragged()
{
  // tie the astronaut to the mouse while we are dragging
  dragging = true;
  astronaut.setPosition(physics.screenToWorld(new Vec2(mouseX, mouseY)));
}

// when we release the mouse, apply an impulse based 
// on the distance from the astronaut to the catapult
void mouseReleased()
{
  dragging = false;
  Vec2 impulse = new Vec2();
  impulse.set(startPoint);
  impulse = impulse.sub(astronaut.getWorldCenter());
  impulse = impulse.mul(50);
  astronaut.applyImpulse(impulse, astronaut.getWorldCenter());
}

// this function renders the physics scene.
// this can either be called automatically from the physics
// engine if we enable it as a custom renderer or 
// we can call it from draw
void myCustomRenderer(World world) {
  
  stroke(0);
  Vec2 screenStartPoint = physics.worldToScreen(startPoint);
  strokeWeight(8);
  line(screenStartPoint.x, screenStartPoint.y, screenStartPoint.x, height);

  // get the droids position and rotation from
  // the physics engine and then apply a translate 
  // and rotate to the image using those values
  // (then do the same for the crates)
  Vec2 screenAstronautPos = physics.worldToScreen(astronaut.getWorldCenter());
  float astronautAngle = physics.getAngle(astronaut);
  pushMatrix();
  translate(screenAstronautPos.x, screenAstronautPos.y);
  rotate(-radians(astronautAngle));
  image(astroImage, 0, 0, astroSize, astroSize);
  popMatrix();

  //make asteroids float
  for (int i = 0; i < asteroids.length; i++)
  {
    Vec2 worldCenter = asteroids[i].getWorldCenter();
    Vec2 asteroidPos = physics.worldToScreen(worldCenter);
    float asteroidAngle = physics.getAngle(asteroids[i]);
    pushMatrix();
    translate(asteroidPos.x, asteroidPos.y);
    rotate(-asteroidAngle);
    image(asterImage,0, 0, asterSize, asterSize);
    popMatrix();
  }

  if (dragging)
  {
    strokeWeight(2);
    line(screenAstronautPos.x, screenAstronautPos.y, screenStartPoint.x, screenStartPoint.y);
  }
}

// This method gets called automatically when 
// there is a collision
void collision(Body b1, Body b2, float impulse)
{
    if ((b1 == astronaut && b2.getMass() > 0)
    || (b2 == astronaut && b1.getMass() > 0))
  {
    if (impulse > 1.0)
    {
      score += 1;
    }
  }
  
  
  // test for droid
  if (b1.getMass() == 0 || b2.getMass() == 0) {// b1 or b2 are walls
    // wall sound
    //println("wall speed "+(impulse/100));
    wallSound.cue(0);
    wallSound.speed(impulse / 100);// 
    wallSound.play();
  }
  if (b1 == astronaut || b2 == astronaut) { // b1 or b2 are the droid
    // droid sound
    println("astronaut "+(impulse/10));
    astronautSound.cue(0);
    astronautSound.speed(impulse / 10);
    astronautSound.play();
  }

  if (b1 == astronaut && b2.getMass() >0) { 
    physics.removeBody(b2);
  }  
  
  if (b1.getMass() > 0 && b2 == astronaut) { 
    physics.removeBody(b1);
  }
 
  
   for (int i=0;i<asteroids.length;i++){
     if (b1 == asteroids[i] || b2 == asteroids[i]){// its a crate
         asteroidSounds[i].cue(0);
         asteroidSounds[i].speed(0.5 + (impulse / 10000));// 10000 as the crates move slower??
         asteroidSounds[i].play();
     }
   }

}

