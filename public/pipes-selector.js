var current;
var targets = [];
var blocked = [];
var selected = [];

document.body.addEventListener("mousemove",function(e) {
    if (current) {
        current.classList.remove('pipes-select-highlight')
    }
    current = document.elementFromPoint(e.x, e.y);
    current.classList.add('pipes-select-highlight');
});
document.body.addEventListener("click",function(e) {
    e.preventDefault();
    var element = e.target;
    if (targets.includes(element)) {
        targets = targets.filter(x => x !== element);
        element.classList.remove('pipes-select-target');
        blocked.push(element);
    } else {
        if (blocked.includes(element)) {
            blocked = blocked.filter(x => x !== element);
            element.classList.remove('pipes-select-blocked');
        } else {
            targets.push(element);
        }
    }

    for (var i=0;i<selected.length;i++) {
        selected[i].classList.remove('pipes-select-selected');
    }
    sel = pipeSelect.select(targets, blocked, {ignore: {classes: ['pipes-select-blocked', 'pipes-select-target', 'pipes-select-highlight']}});
    parent.document.querySelector('#selector').value = sel;
    selected = document.querySelectorAll(sel);

    for (var i=0;i<targets.length;i++) {
        targets[i].classList.add('pipes-select-target');
    }
    for (var i=0;i<blocked.length;i++) {
        blocked[i].classList.add('pipes-select-blocked');
    }
    for (var i=0;i<selected.length;i++) {
        selected[i].classList.add('pipes-select-selected');
    }
});