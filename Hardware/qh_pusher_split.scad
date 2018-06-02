//Quantum Hockey pusher
//by Anghelos

handleRadius = 40 / 2;
handleHeight = 115;
baseRadius = 95 /2;
wallThickness = 2.5;
ledRadius = 5.1 / 2;
handleTaper = 5;
clearance = 0.4; //Tailor's fault
innerHeight = 15;

//bottom
difference(){
    union(){
        //base
        difference(){
            cylinder(h = wallThickness * 2, r = baseRadius, $fn = 80);
            translate([0,0,wallThickness]) cylinder(h = wallThickness * 2, r = baseRadius - wallThickness);
        }
        //handle
        cylinder(h = handleHeight - handleRadius, r1 = handleRadius - handleTaper, r2 = handleRadius);
        
    }
    union(){
        //holes
        difference(){
            cylinder(h = handleHeight - handleRadius, r1 = handleRadius - wallThickness - handleTaper, r2 = handleRadius - wallThickness);
            translate([0,0,-5]) cylinder(h=handleHeight-handleRadius - innerHeight + 5, r = handleRadius);
            }
        translate([0,0, handleHeight - handleRadius]) cylinder(h = 3* wallThickness, r = handleRadius - wallThickness, center = true);
            //battery
            translate([-13.25,-8.75, handleHeight - handleRadius - innerHeight-48.5]) cube([26.5 + clearance, 17.5 + clearance, 48.5 + clearance]);;
    }
}

//Top
union(){
    difference(){
        translate([50,0,handleHeight - handleRadius]) sphere(handleRadius);
        
        //holes
        union(){
            translate([50,0,handleHeight - handleRadius]) sphere(handleRadius - wallThickness - clearance);
            translate([50,0,handleHeight]) cylinder(h = wallThickness * 3, r = ledRadius, center = true);
            translate([50,0,0]) cylinder(h = handleHeight - handleRadius, r = handleRadius + wallThickness);
        }
    }
    difference(){
        translate([50,0,handleHeight - handleRadius]) cylinder(h = wallThickness * 3 - clearance * 2, r = handleRadius - wallThickness -clearance, center =true);
        translate([50,0,handleHeight - handleRadius]) cylinder(h = wallThickness * 4, r = handleRadius - wallThickness -clearance - wallThickness/2, center =true);
    }
    
}
