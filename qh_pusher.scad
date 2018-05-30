handleRadius = 35 / 2;
handleHeight = 90;
baseRadius = 95 /2;
wallThickness = 2.5;
ledRadius = 5.1 / 2;


difference(){
    union(){
        //base
        difference(){
            cylinder(h = wallThickness * 2, r = baseRadius);
            translate([0,0,wallThickness]) cylinder(h = wallThickness * 2, r = baseRadius - wallThickness);
        }
        //handle
        cylinder(h = handleHeight - handleRadius, r = handleRadius);
        translate([0,0,handleHeight - handleRadius]) sphere(handleRadius);
    }
    union(){
        cylinder(h = handleHeight - handleRadius, r = handleRadius - wallThickness);
        sphere(handleRadius - wallThickness);
        translate([0,0,handleHeight - handleRadius]);
        translate([0,0,handleHeight]) cylinder(h = wallThickness * 3, r = ledRadius, center = true);
    }
}
