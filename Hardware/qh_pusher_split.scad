//Quantum Hockey pusher
//by Anghelos

handleRadius = 40 / 2;
handleHeight = 115;
baseRadius = 95 /2;
wallThickness = 4;
ledRadius = 5.2 / 2;
handleTaper = 5;
clearance = 0.1;
innerHeight = 12;

ringHeight = 8;

module handle(){
     cylinder(h = handleHeight - handleRadius, r1 = handleRadius - handleTaper, r2 = handleRadius, $fn = 60);
    }
module handleHole(clr = 0){
    cylinder(h = handleHeight - handleRadius, r1 = handleRadius - wallThickness - handleTaper - clr, r2 = handleRadius - wallThickness - clr);
    }
    
//bottom
module main() {
    difference(){
    union(){
        //base
        difference(){
            cylinder(h = 2.5 * 2, r = baseRadius, $fn = 80);
            translate([0,0,2.5]) cylinder(h = wallThickness * 2, r = baseRadius - 3);
        }
        handle();
        translate([0,0,2.5]) cylinder(h= 5, r1 = baseRadius /2, r2 = handleRadius - handleTaper, $fn = 60 );
        
    }
    union(){
        //holes
            handleHole();
        translate([0,0, handleHeight - handleRadius]) cylinder(h = 3* wallThickness, r = handleRadius - wallThickness, center = true);
            //battery
            translate([-13.25,-8.75, handleHeight - handleRadius - innerHeight-48.5]) cube([26.5, 17.5, 48.5]);
        translate([0,0,handleHeight - handleRadius - ringHeight]) cylinder(h=50, r=50);
    }
}
//switch holder
difference(){
    handle();
    union(){
        cylinder(h = 10, r= handleRadius, center = true);
        translate([0,0,5+9]) cylinder(h = handleHeight, r= handleRadius);
        }
        translate([-2.15,-5.75,5]) cube([4.3, 11.5, 6]);
        translate([-1.25, -4, 0]) cube([2.5,8, 30]);
    }
}
//Top
module lid() {
    union(){
    difference(){
        translate([0,0,handleHeight - handleRadius]) sphere(handleRadius, $fn = 60);
        
        //holes
        union(){
            translate([0,0,handleHeight - handleRadius]) sphere(handleRadius - wallThickness - clearance);
            translate([0,0,handleHeight]) cylinder(h = wallThickness * 3, r = ledRadius, center = true, $fn = 20);
            translate([0,0,0]) cylinder(h = handleHeight - handleRadius, r = handleRadius + wallThickness);
        }
    }
    difference(){
        translate([0,0,handleHeight - handleRadius]) cylinder(h = wallThickness * 2 - clearance * 2, r = handleRadius - wallThickness -clearance, center =true);
        translate([0,0,handleHeight - handleRadius]) cylinder(h = wallThickness * 4, r = handleRadius - wallThickness -clearance - wallThickness/2, center =true);
    }
    
}
}
//ring
module ring(){
    difference(){
        union(){
            difference(){
                handle();
                cylinder(h = handleHeight - handleRadius - ringHeight, r = handleRadius + clearance);
                }
            handleHole();
        }
        
    union(){
        //holes
        translate([0,0, handleHeight - handleRadius]) cylinder(h = 2.5* wallThickness, r = handleRadius - wallThickness, center = true);
        cylinder(h = handleHeight - handleRadius - ringHeight*2, r= handleRadius); 
        translate([-25,-8.75,handleHeight-handleRadius-ringHeight-52]) cube([50, 17.5, 50]);
        handleHole(wallThickness);
    }
    }
}

module mmLid(){
    union(){
    difference(){
        translate([0,0,handleHeight - handleRadius]) sphere(handleRadius, $fn = 60);
        
        //holes
        union(){
            translate([0,0,handleHeight - handleRadius]) sphere(handleRadius - wallThickness);
            translate([0,0,0]) cylinder(h = handleHeight - handleRadius, r = handleRadius + wallThickness);
            //Led
            translate([0,0,handleHeight]) cylinder(h = wallThickness * 3, r = ledRadius, center = true, $fn = 20);
        }
    }
    }
}
//render:
main();
//lid();
translate([50,0,0]) ring();
translate([50,0,0]) mmLid();