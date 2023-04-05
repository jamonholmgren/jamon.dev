document.addEventListener("DOMContentLoaded", () => {
  const canvas = document.getElementById("gameCanvas");
  const ctx = canvas.getContext("2d");
  const viewbox = { x: 0, y: 0, width: canvas.width, height: canvas.height };
  const padding = 50;

  const boundary = { left: padding, right: canvas.width - padding };

  // fog of war
  const offscreenCanvas = document.createElement("canvas");
  offscreenCanvas.width = canvas.width;
  offscreenCanvas.height = canvas.height;
  const offscreenCtx = offscreenCanvas.getContext("2d");

  // grass canvas
  const grassCanvas = document.createElement("canvas");
  grassCanvas.width = canvas.width;
  grassCanvas.height = canvas.height;
  const grassCtx = grassCanvas.getContext("2d");

  drawGrass(grassCtx, grassCanvas.width, grassCanvas.height);

  // Initialize game objects
  const player1 = new Player(1, canvas.width / 4, canvas.height - 50, boundary);
  const player2 = new Player(
    2,
    (canvas.width * 3) / 4,
    canvas.height - 50,
    boundary
  );

  function handleKeyDown(event) {
    // Handle player input
    player1.handleKeyDown(event);
    player2.handleKeyDown(event);
  }
  function handleKeyUp(event) {
    // Handle player input
    player1.handleKeyUp(event);
    player2.handleKeyUp(event);
  }

  function addKeyboardListeners() {
    window.addEventListener("keydown", handleKeyDown);
    window.addEventListener("keyup", handleKeyUp);
  }

  let frameTimes = [];
  let fps = 0;
  let lastRender = Date.now();

  function draw() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // Draw the grass from the offscreen grass canvas
    ctx.drawImage(grassCanvas, 0, 0, canvas.width, canvas.height);

    // Calculate the positions of the tanks relative to the center of the viewport
    const tank1X = player1.tank.x - viewbox.x;
    const tank1Y = player1.tank.y - viewbox.y;
    const tank2X = player2.tank.x - viewbox.x;
    const tank2Y = player2.tank.y - viewbox.y;

    // Adjust the view box position if the tanks are close to the edge of the viewport
    const padding = 50;
    if (tank1X < padding) {
      viewbox.x = player1.tank.x - padding;
    } else if (tank1X > canvas.width - padding) {
      viewbox.x = player1.tank.x + padding - canvas.width;
    }
    if (tank1Y < padding) {
      viewbox.y = player1.tank.y - padding;
    } else if (tank1Y > canvas.height - padding) {
      viewbox.y = player1.tank.y + padding - canvas.height;
    }
    if (tank2X < padding) {
      viewbox.x = player2.tank.x - padding;
    } else if (tank2X > canvas.width - padding) {
      viewbox.x = player2.tank.x + padding - canvas.width;
    }
    if (tank2Y < padding) {
      viewbox.y = player2.tank.y - padding;
    } else if (tank2Y > canvas.height - padding) {
      viewbox.y = player2.tank.y + padding - canvas.height;
    }

    // Draw the tanks and other game elements using the adjusted view box position
    ctx.save();
    ctx.translate(-viewbox.x, -viewbox.y);

    player1.draw(ctx);
    player2.draw(ctx);

    offscreenCtx.globalCompositeOperation = "xor";

    // Clear the offscreenCanvas and fill it with the fog color
    offscreenCtx.clearRect(0, 0, offscreenCanvas.width, offscreenCanvas.height);
    offscreenCtx.fillStyle = "rgba(0, 0, 0, 1.0)";
    offscreenCtx.fillRect(0, 0, offscreenCanvas.width, offscreenCanvas.height);

    // Create the radial gradient and draw the circles with a transparent center and semi-transparent edges
    const revealRadius = 400;
    const gradient1 = offscreenCtx.createRadialGradient(
      player1.tank.x,
      player1.tank.y,
      0,
      player1.tank.x,
      player1.tank.y,
      revealRadius
    );
    gradient1.addColorStop(0, "rgba(0, 0, 0, 1.0)");
    gradient1.addColorStop(0.5, "rgba(0, 0, 0, 1.0)");
    gradient1.addColorStop(1, "rgba(0, 0, 0, 0)");

    const gradient2 = offscreenCtx.createRadialGradient(
      player2.tank.x,
      player2.tank.y,
      0,
      player2.tank.x,
      player2.tank.y,
      revealRadius
    );
    gradient2.addColorStop(0, "rgba(0, 0, 0, 1.0)");
    gradient2.addColorStop(0.5, "rgba(0, 0, 0, 1.0)");
    gradient2.addColorStop(1, "rgba(0, 0, 0, 0)");

    offscreenCtx.globalCompositeOperation = "destination-out";
    offscreenCtx.fillStyle = gradient1;
    offscreenCtx.beginPath();
    offscreenCtx.arc(
      player1.tank.x,
      player1.tank.y,
      revealRadius,
      0,
      2 * Math.PI
    );
    offscreenCtx.fill();

    // offscreenCtx.fillStyle = gradient2;
    // offscreenCtx.beginPath();
    // offscreenCtx.arc(
    //   player2.tank.x,
    //   player2.tank.y,
    //   revealRadius,
    //   0,
    //   2 * Math.PI
    // );
    // offscreenCtx.fill();

    // Draw the offscreenCanvas onto the main canvas using the 'source-over' composite operation
    ctx.globalCompositeOperation = "source-over";
    ctx.drawImage(
      offscreenCanvas,
      viewbox.x,
      viewbox.y,
      canvas.width,
      canvas.height,
      0,
      0,
      canvas.width,
      canvas.height
    );

    ctx.drawImage(offscreenCanvas, viewbox.x, viewbox.y);

    ctx.restore();

    // Calculate time elapsed since last frame was rendered
    const now = Date.now();
    const timeElapsed = now - lastRender;

    // Calculate current FPS
    const currentFps = 1000 / timeElapsed;

    // Update fps list
    frameTimes.push(currentFps);
    // calculate fps as average of last 30 frames, but only every 30 frames
    if (frameTimes.length >= 30) {
      fps = frameTimes.reduce((a, b) => a + b) / frameTimes.length;
      frameTimes = [];
    }

    // Draw fps in top right of window
    ctx.font = "16px Arial";
    ctx.fillStyle = "white";
    ctx.textAlign = "right";
    ctx.fillText(`FPS: ${fps.toFixed(1)}`, canvas.width - 10, 20);

    // Update lastRender variable
    lastRender = now;

    // Request the next frame of animation
    requestAnimationFrame(draw);
  }

  function update() {
    // Update game elements
    player1.update();
    player2.update();

    requestAnimationFrame(update);
  }

  // Initialization
  addKeyboardListeners();
  draw();
  update();
});

class Tank {
  constructor(x, y, angle, color) {
    this.x = x;
    this.y = y;
    this.angle = angle;
    this.color = color;
    this.width = 60;
    this.height = 30;
    this.speed = 0;
    this.maxSpeed = 4;
    this.reverseMaxSpeed = -2;
    this.acceleration = 0.1;
    this.turretAngle = 0;
    this.hp = 100;
    this.crew = {
      TC: { hp: 100, level: 1 },
      Gunner: { hp: 100, level: 1 },
      Driver: { hp: 100, level: 1 },
      Reloader: { hp: 100, level: 1 },
    };

    this.tracks = [];
    this.trackWidth = 10;
    this.trackHeight = 30;
    this.maxTracks = 200;

    this.smokeParticles = [];
    this.maxSmokeParticles = 200;
  }

  draw(ctx) {
    const turretWidth = this.width / 2;
    const turretHeight = this.height / 2;

    this.drawTracks(ctx);
    this.drawSmoke(ctx);

    // Draw the tank body (hull)
    ctx.save();
    ctx.translate(this.x, this.y);
    ctx.rotate(this.angle);

    // Green camo pattern for hull
    const hullPattern = ctx.createPattern(this.createCamoCanvas(), "repeat");
    ctx.fillStyle = hullPattern;

    ctx.beginPath();
    ctx.moveTo(-this.width / 2, -this.height / 2);
    ctx.lineTo(this.width / 2, -this.height / 2);
    ctx.lineTo(this.width / 2, this.height / 2);
    ctx.lineTo(-this.width / 2, this.height / 2);
    ctx.closePath();
    ctx.fill();

    // Draw tank tracks
    ctx.fillStyle = "gray";
    ctx.fillRect(
      -this.width / 2,
      -this.height / 2,
      this.width,
      this.height / 6
    );
    ctx.fillRect(-this.width / 2, this.height / 3, this.width, this.height / 6);

    // Draw shadow below the turret
    ctx.fillStyle = "rgba(0, 0, 0, 0.2)";
    ctx.beginPath();
    ctx.arc(0, turretHeight / 4, turretWidth / 2, 0, Math.PI * 2);
    ctx.closePath();
    ctx.fill();

    // Draw the turret
    ctx.rotate(this.turretAngle);

    // Green camo pattern for turret
    const turretPattern = ctx.createPattern(this.createCamoCanvas(), "repeat");
    ctx.fillStyle = turretPattern;

    ctx.beginPath();
    ctx.arc(0, 0, turretWidth / 2, 0, Math.PI * 2);
    ctx.closePath();
    ctx.fill();

    // Draw the gun
    ctx.fillStyle = this.color;
    ctx.fillRect(
      turretWidth / 4,
      -turretHeight / 8,
      turretWidth / 2,
      turretHeight / 4
    );

    // Make the gun longer
    ctx.fillRect(
      turretWidth / 2,
      -turretHeight / 8,
      turretWidth / 1.5,
      turretHeight / 4
    );

    ctx.restore();
  }

  // Helper method to create a green camo pattern
  createCamoCanvas() {
    const canvas = document.createElement("canvas");
    const ctx = canvas.getContext("2d");
    canvas.width = 50;
    canvas.height = 50;

    // Green camo pattern
    ctx.fillStyle = "#2f4f2f";
    ctx.fillRect(0, 0, 50, 50);
    ctx.fillStyle = "#6b8e23";
    ctx.beginPath();
    ctx.arc(10, 10, 10, 0, Math.PI * 2);
    ctx.closePath();
    ctx.fill();
    ctx.beginPath();
    ctx.arc(30, 30, 10, 0, Math.PI * 2);
    ctx.closePath();
    ctx.fill();
    ctx.beginPath();
    ctx.arc(20, 40, 10, 0, Math.PI * 2);
    ctx.closePath();
    ctx.fill();

    return canvas;
  }

  drawTracks(ctx) {
    this.tracks.forEach((track) => {
      track.draw(ctx);
      track.fade();
    });
    this.tracks = this.tracks.filter((track) => track.getAlpha() > 0);
  }

  dropTracks() {
    const track = new Track(
      this.x,
      this.y,
      this.angle,
      this.trackWidth,
      this.trackHeight
    );
    this.tracks.push(track);
    if (this.tracks.length > this.maxTracks) {
      this.tracks.shift();
    }
  }

  drawSmoke(ctx) {
    this.smokeParticles.forEach((smoke) => {
      smoke.draw(ctx);
      smoke.rise();
    });
    this.smokeParticles = this.smokeParticles.filter(
      (smoke) => smoke.getAlpha() > 0
    );
  }

  emitSmoke() {
    const smoke = new Smoke(this.x, this.y);
    this.smokeParticles.push(smoke);
    if (this.smokeParticles.length > this.maxSmokeParticles) {
      this.smokeParticles.shift();
    }
  }

  accelerate() {
    const maxTurretAngle = Math.PI / 2; // set the maximum turret angle allowed
    const turretAngleFactor = 1 - Math.abs(this.turretAngle) / maxTurretAngle; // calculate the factor based on the turret angle
    const maxSpeedFactor = 0.5 + turretAngleFactor / 2; // calculate the maximum speed factor based on the turret angle factor

    const maxSpeedWithTurretAngle = this.maxSpeed * maxSpeedFactor; // calculate the maximum speed based on the turret angle factor

    this.speed = Math.min(this.speed + 0.1, maxSpeedWithTurretAngle); // set the new speed based on the maximum speed with turret angle

    this.emitSmoke();
  }

  decelerate() {
    this.speed = Math.max(this.speed - 0.1, -this.maxSpeed / 2);
  }

  coast() {
    if (this.speed > 0) {
      this.speed = Math.max(this.speed - 0.1, 0);
    } else if (this.speed < 0) {
      this.speed = Math.min(this.speed + 0.1, 0);
    }
  }

  updatePosition() {
    this.x += this.speed * Math.cos(this.angle);
    this.y += this.speed * Math.sin(this.angle);
  }

  turnTurretLeft() {
    this.turretAngle -= 0.05;

    // if rotated more than one half revolution, add a full revolution
    if (this.turretAngle < -Math.PI) {
      this.turretAngle += Math.PI * 2;
    }
  }

  turnTurretRight() {
    this.turretAngle += 0.05;

    // if rotated more than one half revolution, subtract a full revolution
    if (this.turretAngle > Math.PI) {
      this.turretAngle -= Math.PI * 2;
    }
  }

  alignHullWithTurret() {
    if (Math.abs(this.speed) <= 0.01) return;

    // diff is the difference between the turret angle and the tank angle
    // const diff = this.turretAngle - this.angle;
    const diff = this.turretAngle;
    const snapThreshold = 0.05;

    if (Math.abs(diff) < snapThreshold) {
      this.angle = this.angle + this.turretAngle;
      this.turretAngle = 0;
    } else {
      const sign = Math.sign(diff);
      const absDiff = Math.abs(diff);
      const maxRotation = Math.min(absDiff, 0.01);
      this.angle += sign * maxRotation;

      // rotate the turret the opposite way to "stabilize" it
      this.turretAngle -= sign * maxRotation;
    }
  }

  stayInBounds(boundary) {
    if (this.x < boundary.left) {
      this.x = boundary.left;
    } else if (this.x > boundary.right) {
      this.x = boundary.right;
    }
  }
}

class Depot {
  constructor(x, y) {
    this.x = x;
    this.y = y;
  }

  draw(ctx) {
    // Draw the depot
    ctx.fillStyle = "gray";
    ctx.fillRect(this.x - 30, this.y - 30, 60, 60);

    // Draw the cross
    ctx.beginPath();
    ctx.moveTo(this.x - 15, this.y - 15);
    ctx.lineTo(this.x + 15, this.y + 15);
    ctx.moveTo(this.x - 15, this.y + 15);
    ctx.lineTo(this.x + 15, this.y - 15);
    ctx.strokeStyle = "black";
    ctx.lineWidth = 4;
    ctx.stroke();
  }
}

class Player {
  constructor(id, x, y, boundary) {
    this.id = id;
    // tank is pointing up
    this.tank = new Tank(x, y, -Math.PI / 2, id === 1 ? "green" : "red");

    this.boundary = boundary;

    this.controls = {
      up: id === 1 ? 87 : 38,
      down: id === 1 ? 83 : 40,
      left: id === 1 ? 65 : 37,
      right: id === 1 ? 68 : 39,
      shoot: id === 1 ? 32 : 16,
    };
    this.keyState = {
      up: false,
      down: false,
      left: false,
      right: false,
      shoot: false,
    };
    this.step = 0;
  }

  draw(ctx) {
    this.tank.draw(ctx);
  }

  getTank() {
    return this.tank;
  }

  handleKeyDown(event) {
    switch (event.keyCode) {
      // Player controls
      case this.controls.up:
        this.keyState.up = true;
        break;
      case this.controls.down:
        this.keyState.down = true;
        break;
      case this.controls.left:
        this.keyState.left = true;
        break;
      case this.controls.right:
        this.keyState.right = true;
        break;
      case this.controls.shoot:
        this.keyState.shoot = true;
        break;
    }
  }

  handleKeyUp(event) {
    switch (event.keyCode) {
      // Player controls
      case this.controls.up:
        this.keyState.up = false;
        break;
      case this.controls.down:
        this.keyState.down = false;
        break;
      case this.controls.left:
        this.keyState.left = false;
        break;
      case this.controls.right:
        this.keyState.right = false;
        break;
      case this.controls.shoot:
        this.keyState.shoot = false;
        break;
    }
  }

  update() {
    this.step += 1;
    if (this.step % 10 === 0) {
      this.step10();
    }

    if (this.keyState.up) {
      this.tank.accelerate();
    } else if (this.keyState.down) {
      this.tank.decelerate();
    } else {
      this.tank.coast();
    }

    if (this.keyState.left) {
      this.tank.turnTurretLeft();
    } else if (this.keyState.right) {
      this.tank.turnTurretRight();
    }
    this.tank.updatePosition();
    this.tank.alignHullWithTurret();

    this.tank.stayInBounds(this.boundary);
  }

  step10() {
    if (Math.abs(this.tank.speed) > 0) this.tank.dropTracks();
  }
}

class Track {
  constructor(x, y, angle, width, height) {
    this.x = x;
    this.y = y;
    this.angle = angle;
    this.width = width;
    this.height = height;
    this.alpha = 0.7;
  }

  draw(ctx) {
    ctx.save();
    ctx.translate(this.x, this.y);
    ctx.rotate(this.angle);
    ctx.fillStyle = `rgba(128, 128, 128, ${this.alpha})`;
    ctx.fillRect(-this.width / 2, -this.height / 2, this.width, this.height);
    ctx.restore();
  }

  fade() {
    this.alpha -= 0.001;
  }

  getAlpha() {
    return this.alpha;
  }
}

class Smoke {
  constructor(x, y) {
    this.x = x;
    this.y = y;
    this.radius = 5;
    this.alpha = 0.7;
  }

  draw(ctx) {
    ctx.save();
    ctx.fillStyle = `rgba(100, 100, 100, ${this.alpha})`;
    ctx.beginPath();
    ctx.arc(this.x, this.y, this.radius, 0, Math.PI * 2);
    ctx.closePath();
    ctx.fill();
    ctx.restore();
  }

  rise() {
    this.y -= 0.5;
    this.radius += 0.1;
    this.alpha -= 0.01;
  }

  getAlpha() {
    return this.alpha;
  }
}

function drawGrass(context, width, height) {
  // Set the background color
  context.fillStyle = "#3e8c36";
  context.fillRect(0, 0, width, height);

  // Draw some blades of grass
  context.strokeStyle = "#004d00";
  context.lineWidth = 2;
  context.beginPath();
  for (let i = 0; i < 200; i++) {
    const x = Math.random() * width;
    const y = Math.random() * height;
    context.moveTo(x, y);
    context.lineTo(x + Math.random() * 10, y - Math.random() * 20);
  }
  context.stroke();
}
