//Quantum Hockey pusher
//by Anghelos

handleRadius = 40 / 2;
handleHeight = 95;
baseRadius = 95 /2;
wallThickness = 2.5;
ledRadius = 5.1 / 2;
handleTaper = 7;


difference(){
    union(){
        //base
        difference(){
            cylinder(h = wallThickness * 2, r = baseRadius);
            translate([0,0,wallThickness]) cylinder(h = wallThickness * 2, r = baseRadius - wallThickness);
        }
        //handle
        cylinder(h = handleHeight - handleRadius, r1 = handleRadius - handleTaper, r2 = handleRadius);
        translate([0,0,handleHeight - handleRadius]) sphere(handleRadius);
    }
    union(){
        //holes
        translate([0,0,-wallThickness]) cylinder(h = handleHeight - handleRadius + wallThickness, r1 = handleRadius - wallThickness - handleTaper, r2 = handleRadius - wallThickness);
        translate([0,0,handleHeight - handleRadius]) sphere(handleRadius - wallThickness);
        translate([0,0,handleHeight]) cylinder(h = wallThickness * 3, r = ledRadius, center = true);
    }
}
