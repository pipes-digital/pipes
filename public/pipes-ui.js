Array.prototype.top = function() {
    return this.slice(-1)[0];
}


Raphael.fn.connection = function (obj1, obj2, line, bg) {
    if (obj1.line && obj1.from && obj1.to) {
        line = obj1;
        obj1 = line.from;
        obj2 = line.to;
    }
    
    var bb1 = obj1.getBBox(),
        bb2 = obj2.getBBox(),
        p = [{x: bb1.x + bb1.width / 2, y: bb1.y - 1},
        {x: bb1.x + bb1.width / 2, y: bb1.y + bb1.height + 1},
        {x: bb1.x - 1, y: bb1.y + bb1.height / 2},
        {x: bb1.x + bb1.width + 1, y: bb1.y + bb1.height / 2},
        {x: bb2.x + bb2.width / 2, y: bb2.y - 1},
        {x: bb2.x + bb2.width / 2, y: bb2.y + bb2.height + 1},
        {x: bb2.x - 1, y: bb2.y + bb2.height / 2},
        {x: bb2.x + bb2.width + 1, y: bb2.y + bb2.height / 2}],
        d = {}, dis = [];
    for (var i = 0; i < 4; i++) {
        for (var j = 4; j < 8; j++) {
            var dx = Math.abs(p[i].x - p[j].x),
                dy = Math.abs(p[i].y - p[j].y);
            if ((i == j - 4) || (((i != 3 && j != 6) || p[i].x < p[j].x) && ((i != 2 && j != 7) || p[i].x > p[j].x) && ((i != 0 && j != 5) || p[i].y > p[j].y) && ((i != 1 && j != 4) || p[i].y < p[j].y))) {
                dis.push(dx + dy);
                d[dis[dis.length - 1]] = [i, j];
            }
        }
    }
    if (dis.length == 0) {
        var res = [0, 4];
    } else {
        res = d[Math.min.apply(Math, dis)];
    }
    var x1 = p[res[0]].x,
        y1 = p[res[0]].y,
        x4 = p[res[1]].x,
        y4 = p[res[1]].y;
    dx = Math.max(Math.abs(x1 - x4) / 2, 10);
    dy = Math.max(Math.abs(y1 - y4) / 2, 10);
    var x2 = [x1, x1, x1 - dx, x1 + dx][res[0]].toFixed(3),
        y2 = [y1 - dy, y1 + dy, y1, y1][res[0]].toFixed(3),
        x3 = [0, 0, 0, 0, x4, x4, x4 - dx, x4 + dx][res[1]].toFixed(3),
        y3 = [0, 0, 0, 0, y1 + dy, y1 - dy, y4, y4][res[1]].toFixed(3);
    var path = ["M", x1.toFixed(3), y1.toFixed(3), "C", x2, y2, x3, y3, x4.toFixed(3), y4.toFixed(3)].join(",");
    if (line && line.line) {
        line.bg && line.bg.attr({path: path});
        line.line.attr({path: path});
    } else {
        var color = typeof line == "string" ? line : "#000";
        return {
            bg: bg && bg.split && this.path(path).attr({stroke: bg.split("|")[0], fill: "none", "stroke-width": bg.split("|")[1] || 3}),
            line: this.path(path).attr({stroke: color, fill: "none"}),
            from: obj1,
            to: obj2
        };
    }
};

function unconnect(obj) {
    for (var i = 0; i < connections.length; i++) {
        if (connections[i].from == obj || connections[i].to == obj) {            
            if (connections[i].from.constructor.name == 'TextInput') {
                connections[i].from.block.userinputs[connections[i].from.block.textinputSlot(connections[i].from)].disabled = false;
            }
            if (connections[i].to.constructor.name == 'TextInput') {
                connections[i].to.block.userinputs[connections[i].to.block.textinputSlot(connections[i].to)].disabled = false;
            }
            connections[i].line.remove();
            
            connections[i].from.to = null
            connections[i].from.toSlot = null
            
            connections[i].to.from = null
            connections[i].to.fromSlot = null
            
            connections.splice(i, 1);
        }
    }
}

function connect(connector1, connector2) {
     // Our obj1 always has to be an output ("from"), and obj2 an input ("to")
    if (connector1.constructor.name == 'Input' || connector1.constructor.name == 'TextInput' || connector1.constructor.name == 'PipeOutput') {
        var temp = connector2;
        connector2 = connector1;
        connector1 = temp;
    }
    connections.push(r.connection(connector1, connector2, "#fff"));

    // in the output, we have to store to which block we are going and which slot that is
    connector1.to = connector2.block
    connector1.toSlot = connector2.slot

    // in the input, we have to store from which block we are coming and which slot that is
    connector2.from = connector1.block
    connector2.fromSlot = connector1.slot

    if (connector2.constructor.name == 'TextInput') {
        connector2.block.userinputs[connector2.block.textinputSlot(connector2)].disabled = true;
    }
    if (connector2.constructor.name == 'Input' && connector2.block.growingInputs && connector2.block.inputsFull()) {
        connector2.block.growInputs();
    }
    if (connector1.constructor.name == 'Output' && connector1.block.growingOutputs && connector1.block.outputsFull()) {
        connector1.block.growOutputs();
    }
    setTimeout(() => connector2.block.autofill(connector1.block.id), 100); // delayed so that all connections are set, on init
}    

function showRemovezone() {
    document.querySelector('#blocks').classList.add('removeZone');
}

function hideRemovezone() {
    document.querySelector('#blocks').classList.remove('removeZone');
}

var entityMap = {
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;',
  '"': '&quot;',
  "'": '&#39;',
  '/': '&#x2F;',
  '`': '&#x60;',
  '=': '&#x3D;'
};

function escapeHtml(string) {
  return String(string).replace(/[&<>"'`=\/]/g, function (s) {
    return entityMap[s];
  });
}

function showOutput(block) {
    // get block output from server (pipe output with this block set as root)
    var url = '/block/' + block.id;
    var data = {
        pipe: JSON.stringify(serialize())
    }
    var log = viewer.querySelector('#log');
    log.innerHTML = '<img src="/icons/loader.svg"></img> Loading...';
    viewer.style.display = 'block';
    viewer.dataset['controller'] = block.id;
    viewer.style.left = block.x + block.startlx - ((600 - block.width) / 2) + 'px';
    viewer.style.top = block.y + block.startly + block.height + 52 + 'px';
    postAjax(url, data, function(response) {
            try {
                response = JSON.parse(response);
                log.innerHTML = escapeHtml(vkbeautify.json(JSON.stringify(response.data), 2));
            } catch (e) {
                // not JSON, might be XML
                LoadXMLString(log, response);
                // catch parse error in FF || in blink
                var nodes = log.querySelectorAll('.NodeName');
                if ((nodes.length > 1 && nodes[0].innerHTML == 'parsererror') || (nodes.length > 4 && nodes[4].innerHTML == 'parsererror')) {
                    log.innerHTML = escapeHtml(vkbeautify.xml(response, 2));
                }
            }
        },
        function(errormsg, code) {
            if (code == 401) {
                log.innerHTML = 'Please <a href="#" onclick="showLogin(window.location.pathname);">log-in</a> to see this debug output';
            } else {
                log.innerHTML = 'No result';
            }
        }
    );
}

function dec2hex(dec) {
  return ('0' + dec.toString(16)).substr(-2)
}

function generateId(len) {
    if (typeof window.crypto.getRandomValues === 'function') {
        var arr = new Uint8Array((len || 40) / 2);
        window.crypto.getRandomValues(arr);
        return Array.from(arr, dec2hex).join('');
    } else {
        var s = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        Array(len || 40).join().split(',').map(function() { return s.charAt(Math.floor(Math.random() * s.length)); }).join('');
    }
}

function relCanvasX(posX) {
    return (Number(r.canvas.getAttribute('data-x') || 0) + posX)
}

function relCanvasY(posY) {
    return (Number(r.canvas.getAttribute('data-y') || 0) + posY)
}

var autocompleteRunning = false
function Block(inputAmount, outputAmount, x, y, name, width, height) {
    var that = this,
    lx = 0,
    ly = 0;
    // the initial x position
    this.x = x;
    this.width = width;
    this.height = height;
    // the initial y position
    this.y = y;
    // moved on the x axis after being dragged
    this.startlx = 0;
    // moved on the y axis after being dragged
    this.startly = 0;
    this.base = r.rect(this.x, this.y, this.width, this.height);
    this.base.data("block", that);
    this.outputs = [];
    this.inputs = [];
    this.userinputs = []
    var userinput = document.createElement('input');
    userinput.type = 'text';
    userinput.style.position = 'absolute';
    userinput.setAttribute('data-xoffset', 30);
    userinput.setAttribute('data-yoffset', 20);
    userinput.style.left = x + 30 + 'px';
    userinput.style.top = y +20 + 'px';
    userinput.style.width = '100px';
    userinput.name = 'default';
    this.userinputs.push(userinput)
    document.querySelector('#program').appendChild(userinput);
    
    this.deco = [];
    this.textinputs = [];
    this.growingInputs = false;
    this.growingOutputs = false;
    this.foreachable = false;
    
    this.inspector = r.rect(this.x, this.y + height, width, 25);
    this.inspector.attr({cursor: 'pointer'});
    this.deco.push(this.inspector);
    this.inspectorTitle = r.text(this.x + (width / 2), this.y + height + 12.5, 'view output');
    this.inspectorTitle.attr({'font-size': 15, color: 'white', cursor: 'pointer'});
    this.deco.push(this.inspectorTitle);
    this.titleBox = r.rect(this.x, this.y - 25, width, 25);
    this.name = name;
    this.title = r.text(this.x + (width / 2), this.y - 12, name);
    this.title.attr({'font-size': 20});
    this.deco.push(this.titleBox);
    this.titleEdit = r.text(this.x + (width - 10), this.y - 10, '🖉');
    this.titleEdit.attr({'font-size': 15})
    this.deco.push(this.titleEdit);

    this.dropzone = []; // used in the foreach block
    this.autofillData = []; // used for custom implementations of autofill

    this.titleEdit.click(function() {
        vex.dialog.prompt({
                message: 'Name block:',
                placeholder: that.name,
                callback: function(data) {
                    if (data) {
                        that.setName(data);
                        styleBlock(that);
                    }
                }
                
            });
    });

    this.setName = function(data) {
        that.name = data;
        newTitle = r.text(that.x + (width / 2), that.y - 12, data);
        newTitle.transform('T' + that.startlx + ',' + that.startly);
        newTitle.attr({'font-size': 20});
        newTitle.drag(move, start, end).onDragOver( function(hovered) { collide(hovered, that);});
        newTitle.insertAfter(that.title)
        that.title.remove();
        that.title = newTitle;
    };
     
    this.inspector.click(function() {
        showOutput(that);
    });
    this.inspectorTitle.click(function() {
        showOutput(that);
    });
    this.inspector.hover(function() {
        this.animate({"fill-opacity": .7}, 500);
    }, function() {
        this.animate({"fill-opacity": 1}, 500);
    });
    this.inspectorTitle.hover(function() {
        that.inspector.animate({"fill-opacity": .7}, 500);
    });

    
    this.id = generateId(10);

    switch (inputAmount) {
        case 1:
            var input = new Input(this.x, this.y + height / 2, this, 0);
            this.inputs.push(input);
            break
        case 2:
            var input = new Input(this.x, this.y + 15, this, 0);
            this.inputs.push(input);
            var input = new Input(this.x, this.y + height - 15, this, 1);
            this.inputs.push(input);
            break
        case 3:
            var input = new Input(this.x, this.y + 15, this, 0);
            this.inputs.push(input);
            var input = new Input(this.x, this.y + height / 2, this, 1);
            this.inputs.push(input);
            var input = new Input(this.x, this.y + height - 15, this, 2);
            this.inputs.push(input);
            break
        case 4:
            if (name === "Build Feed") {
                var input = new Input(this.x, this.y + 95, this, 0);
                this.inputs.push(input);
                var input = new Input(this.x, this.y + 130 , this, 1);
                this.inputs.push(input);
                var input = new Input(this.x, this.y + 165, this, 2);
                this.inputs.push(input);
                var input = new Input(this.x, this.y + 200, this, 3);
                this.inputs.push(input);
            } else {
                var input = new Input(this.x, this.y + 15, this, 0);
                this.inputs.push(input);
                var input = new Input(this.x, this.y + (height / 4) + 17.5 , this, 1);
                this.inputs.push(input);
                var input = new Input(this.x, this.y + ((height / 4) * 3) - 17.5, this, 2);
                this.inputs.push(input);
                var input = new Input(this.x, this.y + height - 15, this, 3);
                this.inputs.push(input);
            }
            break
        case 5:
            var input = new Input(this.x, this.y + 15, this, 0);
            this.inputs.push(input);
            var input = new Input(this.x, this.y + (height / 5) + 17.5, this, 1);
            this.inputs.push(input);
            var input = new Input(this.x, this.y + height / 2, this, 2);
            this.inputs.push(input);
            var input = new Input(this.x, this.y + ((height / 5) * 4) - 17.5, this, 3);
            this.inputs.push(input);
            var input = new Input(this.x, this.y + height - 15, this, 4);
            this.inputs.push(input);
            break
    }

    switch (outputAmount) {
        case 1:
            var output = new Output(this.x + width, this.y + height / 2, this, 0);
            this.outputs.push(output);
            break
        case 2:
            var output = new Output(this.x + width, this.y + 15, this, 0);
            this.outputs.push(output);
            var output = new Output(this.x + width, this.y + height - 15, this, 1);
            this.outputs.push(output);
            break
        case 3:
            var output = new Output(this.x + width, this.y + 15, this, 0);
            this.outputs.push(output);
            var output = new Output(this.x + width, this.y + height / 2, this, 1);
            this.outputs.push(output);
            var output = new Output(this.x + width, this.y + height - 15, this, 2);
            this.outputs.push(output);
            break
        case 4:
            var output = new Output(this.x + width, this.y + 15, this, 0);
            this.outputs.push(output);
            var output = new Output(this.x + width, this.y + height / 4 + 17.5, this, 1);
            this.outputs.push(output);
            var output = new Output(this.x + width, this.y + ((height / 4) * 3) - 17.5, this, 2);
            this.outputs.push(output);
            var output = new Output(this.x + width, this.y + height - 15, this, 3);
            this.outputs.push(output);
            break
        case 5:
            var output = new Output(this.x + width, this.y + 15, this, 0);
            this.outputs.push(output);
            var output = new Output(this.x + width, this.y + (height / 5) + 17.5, this, 1);
            this.outputs.push(output);
            var output = new Output(this.x + width, this.y + height / 2, this, 2);
            this.outputs.push(output);
            var output = new Output(this.x + width, this.y + ((height / 5) * 4) - 17.5, this, 3);
            this.outputs.push(output);
            var output = new Output(this.x + width, this.y + height - 15, this, 4);
            this.outputs.push(output);
            break
    }

    this.growInputs = function() {
        var grow = this.inputs[1].base.getBBox().y - this.inputs[0].base.getBBox().y;
        this.height += grow;
        this.base.attr({height: this.height});
        this.inspector.attr({y: this.y + this.height});
        this.inspectorTitle.attr({y: this.y + this.height + 12.5});
        var input = new Input(this.x + this.startlx, this.y + this.startly + this.height - 15, this, this.inputs.length);
        input.base.transform('T' + this.startlx  + ' , ' + this.startly);
        this.inputs.push(input);
        styleBlock(this);
    }

    this.inputsFull = function() {
        for (var i = 0; i < this.inputs.length; i++) {
            if (typeof(this.inputs[i].from) == 'undefined') {
                return false;
            }
        }
        return true;
    }
    
    this.growOutputs = function() {
        var grow = this.outputs[1].base.getBBox().y - this.outputs[0].base.getBBox().y;
        this.height += grow;
        this.base.attr({height: this.height});
        this.inspector.attr({y: this.y + this.height});
        this.inspectorTitle.attr({y: this.y + this.height + 12.5});
        var output = new Output(this.x + this.width, this.y + this.height - 15, this, this.outputs.length);
        output.base.transform('T' + this.startlx  + ' , ' + this.startly);
        this.outputs.push(output);
        styleBlock(this);
    }

    this.outputsFull = function() {
        for (var i = 0; i < this.outputs.length; i++) {
            if (typeof(this.outputs[i].to) == 'undefined') {
                return false;
            }
        }
        return true;
    }
    
    this.attr = function(props) {
        this.base.attr(props);
        this.outputs.forEach(function(elem) {
            elem.attr(props);
        });
        this.inputs.forEach(function(elem) {
            elem.attr(props);
        });        
        this.textinputs.forEach(function(elem) {
            elem.attr(props);
        });        
    };

    this.inRemoveZone = function() {
        var x = this.base.getBBox().x;
        if (x < relCanvasX(200)) {
            return true;
        } else {
            return false;
        }
    };

    this.remove = function() {
        storeState(this);
        this.base.remove();
        this.inputs.forEach(function(elem) {
            elem.remove();
        });
        this.outputs.forEach(function(elem) {
            elem.remove();
        });
        this.userinputs.forEach(function(elem) {
            elem.remove();
        });
        this.dropzone.forEach(function(elem) {
            elem.remove();
        });
        this.textinputs.forEach(function(elem) {
            elem.remove();
        });
        this.deco.forEach(function(elem) {
            elem.remove();
        });
        this.title.remove();
        blocks.splice(blocks.indexOf(this), 1);
        // We also need to close the inspector if it happens to be open
        if (viewer.dataset.controller == this.id) {
            viewer.style.display = 'none';
        }
    };
    
    var start = function () {
        showRemovezone();
        that.base.animate({fill: '#D2D2D2'}, 500);
    },
    move = function (dx, dy) {
        lx = dx + that.startlx;
        ly = dy + that.startly;
        that.base.transform('T' + lx + ',' + ly);
        that.title.transform('T' + lx  + ' , ' + ly);
        that.outputs.forEach(function(elem) {
            elem.transform('T' + lx  + ' , ' + ly);
        });
        that.inputs.forEach(function(elem) {
            elem.transform('T' + lx  + ' , ' + ly);
        });
        that.textinputs.forEach(function(elem) {
            elem.transform('T' + lx  + ' , ' + ly);
        });
        that.deco.forEach(function(elem) {
            elem.transform('T' + lx  + ' , ' + ly);
        });
        that.dropzone.forEach(function(elem) {
            elem.transform('T' + lx  + ' , ' + ly);
        });
        that.userinputs.forEach(function(elem, index) {
            elem.style.left = (x + lx) + Number(elem.getAttribute('data-xoffset')) + 'px';
            elem.style.top = (y + ly) + Number(elem.getAttribute('data-yoffset')) + 'px'
        });

        if (viewer && viewer.dataset.controller == that.id) {
            viewer.style.left = x  - ((600 - width) / 2) + lx + 'px';
            viewer.style.top = y + height + 52 + + ly + 'px'; 
        }

        connections.forEach(function(connection) {
            r.connection(connection);
        });
    },
    end = function () {
        that.startlx = lx;
        that.startly = ly;
        
        that.base.animate({fill: '#E5E5E5'}, 500);
        if (that.inRemoveZone()) {
            that.remove();
        }
            
        hideRemovezone();
        if (foreachtarget != null) {
            foreachtarget.data('block').convert(that);
            foreachtarget = null;
            that.remove();
        }
    };
    
    this.outputSlot = function(target) {
        for (var i=0; i < outputAmount; i++) {
            if (that.outputs[i].to && (that.outputs[i].to.id == target)) {
                return i;
            }
        }
    };

    this.textinputSlot = function(connector) {
        for (var i=0; i < that.textinputs.length; i++) {
            if (connector == that.textinputs[i]) {
                return i;
            }
        }
    }
    
    this.base.drag(move, start, end).onDragOver( function(hovered) { collide(hovered, that);});
    this.titleBox.drag(move, start, end).onDragOver( function(hovered) { collide(hovered, that);});
    this.title.drag(move, start, end).onDragOver( function(hovered) { collide(hovered, that);});

    this.serialize = function() {
        userinputValues = []
        oldConnections = []
        for (var i=0; i < this.userinputs.length; i++) {
            userinputValues.push(this.userinputs[i].value);
        }
        for (var i=0; i < this.inputs.length; i++) {
            try {
                oldConnections.push({fromId: this.inputs[i].from.id, fromSlot: this.inputs[i].fromSlot, toId: this.inputs[i].block.id, toSlot: this.inputs[i].toSlot});
            } catch(error) {}
        }
        for (var i=0; i < this.outputs.length; i++) {
            try {
                oldConnections.push({fromId: this.outputs[i].block.id, fromSlot: this.outputs[i].fromSlot, toId: this.outputs[i].to.id, toSlot: this.outputs[i].toSlot});
            } catch(error) {}
        }

        return {type: this.constructor.name, x: x, y: y, id: this.id, userinputValues: userinputValues, oldConnections: oldConnections, name: this.name}
    }
    // If the specific block has autofilled inputs, this gets the outline data from the server
    // and calls the block implementation of autofillInputs
    this.autofill = function(originId) {
        if (typeof that.autofillInputs !== 'undefined') {
            if (autocompleteRunning) {
                setTimeout(() => {
                    that.autofill(originId)
                }, 100);
            } else {
                autocompleteRunning = true;
                
                // 1. Get autofill outline from server
                var url = '/block/' + originId;
                var data = {
                    pipe: JSON.stringify(serialize())
                }

                postAjax(url, data, function(response) {
                        try {
                            response = JSON.parse(response);
                            that.autofillData = response.paths;
                            // 2. Call autofillInputs
                            that.autofillInputs();
                        } catch (e) {
                            console.log('automplete error:');
                            console.log(e);
                            // Nothing to do. 
                        }
                        autocompleteRunning = false;
                    },
                    function(errormsg, code) {
                        // TODO: Show visible error
                        console.log(errormsg);
                        autocompleteRunning = false;
                    }
                );
            }
        }
    }
}

var foreachtarget = null;
function collide(hovered, origin) {
    if (origin.foreachable && hovered.data("block") && hovered.data("block").constructor.name == "ForeachBlock") {
        hovered.data("block").highlightDropzone();
        foreachtarget = hovered;
    } else {
        if (foreachtarget != null) {
            foreachtarget.data("block").unhighlightDropzone();
            foreachtarget = null;
        }
    }
}

function TextinputBlock(x, y) {
    Block.call(this, 0, 1, x, y, 'Text Input', 200, 110);
    this.userinputs[0].type = 'text';
    this.userinputs[0].required = true;
    this.userinputs[0].style.width = '150px';
    this.userinputs[0].placeholder = 'name';

    var userinput = document.createElement('input');
    userinput.type = 'text';
    userinput.style.width = '150px';
    userinput.style.position = 'absolute';
    userinput.setAttribute('data-xoffset', 30);
    userinput.setAttribute('data-yoffset', 60);
    userinput.style.left = x + 30 + 'px';
    userinput.style.top = y + 60 + 'px';
    userinput.name = 'default';
    userinput.placeholder = 'default';
    document.querySelector('#program').appendChild(userinput);
    this.userinputs.push(userinput)    
    
    this.inspector.remove();
    this.inspectorTitle.remove();

    this.outputs[0].remove()
    
    var output = new TextOutput(x + 200, y + 50, this);
    this.outputs[0] = output;
}


function FeedBlock(x, y) {
    Block.call(this, 0, 1, x, y, 'Feed', 200, 100);
    this.userinputs[0].type = 'url';
    this.userinputs[0].required = true;
    this.userinputs[0].style.width = '150px';
    this.userinputs[0].placeholder = 'https://...';

    var textinput = new TextInput(x + 29, y + 37, this);
    this.textinputs.push(textinput);
    this.foreachable = true;
}

function DownloadBlock(x, y) {
    Block.call(this, 0, 1, x, y, 'Download', 200, 100);
    this.userinputs[0].type = 'url';
    this.userinputs[0].required = true;
    this.userinputs[0].style.width = '150px';
    this.userinputs[0].placeholder = 'https://...';

    var userinput = document.createElement('input');
    userinput.type = 'checkbox';
    userinput.disabled = true;
    userinput.style.position = 'absolute';
    userinput.setAttribute('data-xoffset', 30);
    userinput.setAttribute('data-yoffset', 70);
    userinput.style.left = x + 30 + 'px';
    userinput.style.top = y + 70 + 'px';
    userinput.name = 'js';
    document.querySelector('#program').appendChild(userinput);
    this.deco.push(r.text(x + 50, y + 77, 'Execute JavaScript' ).attr({'text-anchor': 'start'}));
    
    if (pipesPlan) {
        // user is on a paid plan
        userinput.disabled = false;
    }
    this.userinputs.push(userinput);

    var textinput = new TextInput(x + 29, y + 37, this);
    this.textinputs.push(textinput);
    this.foreachable = true;
}

function WateredDownloadBlock(x, y) {
    Block.call(this, 0, 1, x, y, 'Download', 200, 100);
    this.userinputs[0].type = 'url';
    this.userinputs[0].required = true;
    this.userinputs[0].style.width = '150px';
    this.userinputs[0].placeholder = 'https://...';

    var userinput = document.createElement('input');
    userinput.type = 'checkbox';
    userinput.disabled = true;
    userinput.style.position = 'absolute';
    userinput.setAttribute('data-xoffset', 30);
    userinput.setAttribute('data-yoffset', 70);
    userinput.style.left = x + 30 + 'px';
    userinput.style.top = y + 70 + 'px';
    userinput.name = 'js';
    document.querySelector('#program').appendChild(userinput);
    this.deco.push(r.text(x + 50, y + 77, 'Execute JavaScript' ).attr({'text-anchor': 'start'}));
    
    if (pipesPlan) {
        // user is on a paid plan
        userinput.disabled = false;
    }
    this.userinputs.push(userinput);

    var textinput = new TextInput(x + 29, y + 37, this);
    this.textinputs.push(textinput);
}

function CombineBlock(x, y) {
    Block.call(this, 5, 1, x, y, 'Combine', 150, 200);
    this.userinputs[0].type = 'hidden';
    this.growingInputs = true;
}

function DuplicateBlock(x, y) {
    Block.call(this, 1, 5, x, y, 'Duplicate', 150, 200);
    this.userinputs[0].type = 'hidden';
    this.growingOutputs = true;
}

function WateredDuplicateBlock(x, y) {
    Block.call(this, 1, 5, x, y, 'Duplicate', 150, 200);
    this.userinputs[0].type = 'hidden';
    this.growingOutputs = true;
}


function ForeachBlock(x, y) {
    Block.call(this, 1, 1, x, y, 'ForEach', 250, 200);
    var that = this;
    this.userinputs[0].type = 'hidden';
    this.growingInputs = false;
    // the landing zone for valid input blocks:
    this.deco.push(r.path("M" + (x) + " " + (y + 100) + "H" + (x + 50) ));
    this.dropzone.push(r.path("M" + (x + 50) + " " + (y + 100) + "V" + (y + 50) + "H" + (x + 200) + "V" + (y + 87) + "M" + (x + 200) + " " + (y + 113) + "V" + (y + 150) + "H" + (x + 50) + "V" + (y + 100) ));
    this.deco.push(r.path("M" + (x + 213) + " " + (y + 100) + "H" + (x + 250) ));
    this.dropzone.push(r.path("M" + (x + 50) + " " + (y + 100) + "H" + (x + 65)  + "V" + (y + 80) + "H" + (x + 70)))
    this.dropzone.push(r.path("M" + (x + 80) + " " + (y + 70) + "H" + (x + 160) + "V" + (y + 90) +  "H" + (x + 80) ));
    this.dropzone.push(sector(x + 80, y + 80,10,90,270,{}));
    this.dropzone.push(sector(x + 200, y + 100, 13,-90,90,{}));
    this.dropzone.push(r.path("M" + (x + 50) + " " + (y + 50) + "V" + (y + 30)  + "H" + (x + 200) + "V" + (y + 50)))

    this.dropzone.forEach(function(elem) {
        elem.attr({'stroke-dasharray': '.'});
    });
    that.userinputs[0].dataset.value = 'empty'; // we set the value as a dataset here, because for some reason setting the value (also with setAttribute) does not persist in serlalize later

    this.convertToDownload = function() {
        if (that.dropzone.top().type == 'text') {
            // we need to remove the prior digested title
            that.dropzone.pop().remove();
        }
        that.dropzone.forEach(function(elem) {
            elem.attr({'stroke-dasharray': 'none'});
        });

        var title = r.text(that.x + (that.width / 2), that.y + 40, "Download");
        title.attr({'font-size': 16});
        that.dropzone.push(title);
        that.userinputs[0].dataset.value = 'download';
    };

    this.convertToFeed = function() {
        if (that.dropzone.top().type == 'text') {
            // we need to remove the prior digested title
            that.dropzone.pop().remove();
        }
        that.dropzone.forEach(function(elem) {
            elem.attr({'stroke-dasharray': 'none'});
        });

        var title = r.text(that.x + (that.width / 2), that.y + 40, "Feed");
        title.attr({'font-size': 16});
        that.dropzone.push(title);
        that.userinputs[0].dataset.value = 'feed';
    };
    
    this.convertToTweets = function() {
        if (that.dropzone.top().type == 'text') {
            // we need to remove the prior digested title
            that.dropzone.pop().remove();
        }
        that.dropzone.forEach(function(elem) {
            elem.attr({'stroke-dasharray': 'none'});
        });

        var title = r.text(that.x + (that.width / 2), that.y + 40, "Tweets");
        title.attr({'font-size': 16});
        that.dropzone.push(title);
        that.userinputs[0].dataset.value = 'tweets';
    };
    this.highlightDropzone = function() {
        that.base.attr({"fill": "#F3F3C0"});
    };
    this.unhighlightDropzone = function() {
        that.base.attr({"fill": blockBackground});
    };
    this.convert = function(block) {
        if (typeof block === "undefined") {
            // used when unserializing a pipe
            if (that.userinputs[0].value == "download") {
                that.convertToDownload();
            }   
            if (that.userinputs[0].value == "feed") {
                that.convertToFeed();
            }   
            if (that.userinputs[0].value == "tweets") {
                that.convertToTweets();
            }
        } else {
            if (block.constructor.name == "FeedBlock") {
                that.convertToFeed();
            }
            if (block.constructor.name == "DownloadBlock") {
                that.convertToDownload();
            }
            if (block.constructor.name == "TwitterBlock") {
                that.convertToTweets();
            }
            that.unhighlightDropzone();
        }
    };
}

var rad = Math.PI / 180;
function sector(cx, cy, radius, startAngle, endAngle, params) {
        var x1 = cx + radius * Math.cos(-startAngle * rad),
            x2 = cx + radius * Math.cos(-endAngle * rad),
            y1 = cy + radius * Math.sin(-startAngle * rad),
            y2 = cy + radius * Math.sin(-endAngle * rad);
    return r.path(["M", cx, cy, "L", x1, y1, "A", radius, radius, 0, +(endAngle - startAngle > 180), 0, x2, y2, "z"]).attr(params);
}

function FilterBlock(x, y) {
    Block.call(this, 1, 1, x, y, 'Filter', 200, 150);
    this.userinputs[0].style.width = '150px';
    this.userinputs[0].required = true;
    this.userinputs[0].placeholder = 'keyword';
    var textinput = new TextInput(x + 29, y + 37, this);
    this.textinputs.push(textinput);

    var userinput = document.createElement('input');
    userinput.type = 'checkbox';
    userinput.style.position = 'absolute';
    userinput.setAttribute('data-xoffset', 30);
    userinput.setAttribute('data-yoffset', 115);
    userinput.style.left = x + 30 + 'px';
    userinput.style.top = y + 115 + 'px';
    userinput.name = 'block';
    document.querySelector('#program').appendChild(userinput);
    this.userinputs.push(userinput)
    
    var field = document.createElement('select');
    var all = document.createElement('option');
    all.value = 'all';
    all.text = 'all';
    var content = document.createElement('option');
    content.value = 'content';
    content.text = 'item.content';
    var summary = document.createElement('option');
    summary.value = 'summary';
    summary.text = 'item.summary';
    var description = document.createElement('option');
    description.value = 'description';
    description.text = 'item.description';
    var title = document.createElement('option');
    title.value = 'title';
    title.text = 'item.title';
    var link = document.createElement('option');
    link.value = 'link';
    link.text = 'item.link';
    var category = document.createElement('option');
    category.value = 'category';
    category.text = 'item.category';
    var author = document.createElement('option');
    author.value = 'author';
    author.text = 'item.author';
    field.appendChild(all);
    field.appendChild(content);
    field.appendChild(summary);
    field.appendChild(description);
    field.appendChild(title);
    field.appendChild(link);
    field.appendChild(category);
    field.appendChild(author);
    field.style.position = 'absolute';
    field.setAttribute('data-xoffset', 30);
    field.setAttribute('data-yoffset', 75);
    field.style.left = x + 30 + 'px';
    field.style.top = y + 75 + 'px';
    field.style.width = '150px';
    field.name = 'field';
    document.querySelector('#program').appendChild(field);
    this.userinputs.push(field)
    
    this.deco.push(r.text(x + 30, y + 67, 'search in fields:' ).attr({'text-anchor': 'start'}));
    this.deco.push(r.text(x + 50, y + 122, 'block found items' ).attr({'text-anchor': 'start'}));
}

function WateredFilterBlock(x, y) {
    Block.call(this, 1, 1, x, y, 'Filter (structured)', 475, 130);
    this.userinputs[0].style.width = '425px';
    this.userinputs[0].required = true;
    this.userinputs[0].placeholder = 'Filter this';
    var textinput = new TextInput(x + 29, y + 36, this);
    this.textinputs.push(textinput);
    var textinput = new TextInput(x + 29, y + 91, this);
    this.textinputs.push(textinput);
    var textinput = new TextInput(x + 304, y + 91, this);
    this.textinputs.push(textinput);
    
    var userinput = document.createElement('input');
    userinput.style.position = 'absolute';
    userinput.setAttribute('data-xoffset', 30);
    userinput.setAttribute('data-yoffset', 75);
    userinput.style.left = x + 30 + 'px';
    userinput.style.top = y + 75 + 'px';
    userinput.style.width = '150px';
    userinput.name = 'field';
    userinput.placeholder = 'when this';
    document.querySelector('#program').appendChild(userinput);
    this.userinputs.push(userinput)

    var userinput = document.createElement('input');
    userinput.style.position = 'absolute';
    userinput.setAttribute('data-xoffset', 305);
    userinput.setAttribute('data-yoffset', 75);
    userinput.style.left = x + 305 + 'px';
    userinput.style.top = y + 75 + 'px';
    userinput.style.width = '150px';
    userinput.name = 'keyword';
    userinput.placeholder = 'that';
    document.querySelector('#program').appendChild(userinput);
    this.userinputs.push(userinput)


    var userinput = document.createElement('select');
    
    var contains = document.createElement('option');
    contains.value = 'contains';
    contains.text = 'contains';
    var misses = document.createElement('option');
    misses.value = 'misses';
    misses.text = 'misses';
    var regexp = document.createElement('option');
    regexp.value = 'regexp';
    regexp.text = 'regexp';
    
    userinput.appendChild(contains);
    userinput.appendChild(misses);
    userinput.appendChild(regexp);
    userinput.style.position = 'absolute';
    userinput.setAttribute('data-xoffset', 185);
    userinput.setAttribute('data-yoffset', 75);
    userinput.style.left = x + 185 + 'px';
    userinput.style.top = y + 75 + 'px';
    userinput.style.width = '100px';
    userinput.name = 'field';
    document.querySelector('#program').appendChild(userinput);
    this.userinputs.push(userinput)
    
    this.deco.push(r.text(x + 30, y + 67, 'remove when:' ).attr({'text-anchor': 'start'}));
    // Will be called when a block connects to this block. 
    this.autofillInputs = function() {
        const datalist = document.createElement('datalist');
        datalist.id = 'paths' + this.id;
        for (const item of this.autofillData) {
            datalist.appendChild(new Option(item,item));
        }
        oldList = document.querySelector('#paths' + this.id);
            if (oldList != null) {
                oldList.remove()
            }
        document.querySelector('#program').appendChild(datalist);
        this.userinputs[0].setAttribute('list', datalist.id);
        // to init autocomplete of the second field on page load:
        this.userinputs[0].dispatchEvent(new Event("blur"));
    }
    
    this.userinputs[0].addEventListener('blur', (event) => {
        if (this.userinputs[0].list) {
            // Autocomplete was initialized, now adapt the subfield autocomplete to the selected
            // field
            const datalist = document.createElement('datalist');
            datalist.id = 'subpaths' + this.id;
            for (const item of this.autofillData) {
                if (item.startsWith(this.userinputs[0].value)) {
                                                                              // +1 for the dot
                    var target = item.substring(this.userinputs[0].value.length);
                    if (target.startsWith('[*].')) {
                        target = target.substring(4);
                    }
                    datalist.appendChild(new Option(target,target));
                }
            }
            // in case there was one already we remove it
            oldList = document.querySelector('#subpaths' + this.id);
            if (oldList != null) {
                oldList.remove()
            }
            document.querySelector('#program').appendChild(datalist);
            this.userinputs[1].setAttribute('list', datalist.id);
        }
    })
}

function FilterlangBlock(x, y) {
    Block.call(this, 1, 1, x, y, 'Filter Language', 200, 150);
    this.userinputs[0].remove();
    
    var languages = document.createElement('select');
    const langOptions = ['chinese', 'english', 'german', 'finnish', 'french', 'italian', 'russian', 'spanish', 'turkish'];
    for (const language of langOptions) {
        let temp = document.createElement('option');
        temp.value = language;
        temp.text = language;
        languages.appendChild(temp);
    }
    
    languages.style.position = 'absolute';
    languages.setAttribute('data-xoffset', 30);
    languages.setAttribute('data-yoffset', 30);
    languages.style.left = x + 30 + 'px';
    languages.style.top = y + 30 + 'px';
    languages.style.width = '150px';
    languages.name = 'languages';

    this.userinputs[0] = languages
    document.querySelector('#program').appendChild(languages);
    var userinput = document.createElement('input');
    userinput.type = 'checkbox';
    userinput.style.position = 'absolute';
    userinput.setAttribute('data-xoffset', 30);
    userinput.setAttribute('data-yoffset', 115);
    userinput.style.left = x + 30 + 'px';
    userinput.style.top = y + 115 + 'px';
    userinput.name = 'block';
    document.querySelector('#program').appendChild(userinput);
    this.userinputs.push(userinput)
    
    var field = document.createElement('select');
    var all = document.createElement('option');
    all.value = 'all';
    all.text = 'all';
    var content = document.createElement('option');
    content.value = 'content';
    content.text = 'item.content';
    var summary = document.createElement('option');
    summary.value = 'summary';
    summary.text = 'item.summary';
    var description = document.createElement('option');
    description.value = 'description';
    description.text = 'item.description';
    var title = document.createElement('option');
    title.value = 'title';
    title.text = 'item.title';;
    field.appendChild(all);
    field.appendChild(content);
    field.appendChild(summary);
    field.appendChild(description);
    field.appendChild(title);
    field.style.position = 'absolute';
    field.setAttribute('data-xoffset', 30);
    field.setAttribute('data-yoffset', 75);
    field.style.left = x + 30 + 'px';
    field.style.top = y + 75 + 'px';
    field.style.width = '150px';
    field.name = 'field';
    document.querySelector('#program').appendChild(field);
    this.userinputs.push(field)
    
    this.deco.push(r.text(x + 30, y + 67, 'search in fields:' ).attr({'text-anchor': 'start'}));
    this.deco.push(r.text(x + 30, y + 23, 'filter language:' ).attr({'text-anchor': 'start'}));
    this.deco.push(r.text(x + 50, y + 122, 'remove items in this language' ).attr({'text-anchor': 'start'}));
}

function ShortenBlock(x, y) {
    Block.call(this, 1, 1, x, y, 'Shorten', 200, 150);
    this.userinputs[0].style.width = '150px';
    this.userinputs[0].required = true;
    this.userinputs[0].placeholder = '200';
    this.userinputs[0].type = 'number';
    var textinput = new TextInput(x + 29, y + 37, this);
    this.textinputs.push(textinput);
    
    var field = document.createElement('select');
    var content = document.createElement('option');
    content.value = 'content';
    content.text = 'item.content';
    var summary = document.createElement('option');
    summary.value = 'summary';
    summary.text = 'item.summary';
    var title = document.createElement('option');
    title.value = 'title';
    title.text = 'item.title';
   
    field.appendChild(content);
    field.appendChild(summary);
    field.appendChild(title);
    field.style.position = 'absolute';
    field.setAttribute('data-xoffset', 30);
    field.setAttribute('data-yoffset', 75);
    field.style.left = x + 30 + 'px';
    field.style.top = y + 75 + 'px';
    field.style.width = '150px';
    field.name = 'field';
    document.querySelector('#program').appendChild(field);
    this.userinputs.push(field)
    
    this.deco.push(r.text(x + 30, y + 67, 'search in fields:' ).attr({'text-anchor': 'start'}));
}

function ReplaceBlock(x, y) {
    Block.call(this, 1, 1, x, y, 'Replace', 200, 150);
    this.userinputs[0].style.width = '150px';
    this.userinputs[0].required = true;
    this.userinputs[0].placeholder = 'keyword';
    var userinput = document.createElement('input');
    userinput.type = 'text';
    userinput.style.width = '150px';
    userinput.style.position = 'absolute';
    userinput.setAttribute('data-xoffset', 30);
    userinput.setAttribute('data-yoffset', 60);
    userinput.style.left = x + 30 + 'px';
    userinput.style.top = y + 60 + 'px';
    userinput.name = 'replace';
    userinput.placeholder = 'replacement';
    document.querySelector('#program').appendChild(userinput);
    this.userinputs.push(userinput)

    var field = document.createElement('select');
    var all = document.createElement('option');
    all.value = 'all';
    all.text = 'all (except guid)';
    var content = document.createElement('option');
    content.value = 'content';
    content.text = 'item.content';
    var summary = document.createElement('option');
    summary.value = 'summary';
    summary.text = 'item.summary';
    var title = document.createElement('option');
    title.value = 'title';
    title.text = 'item.title';
    var guid = document.createElement('option');
    guid.value = 'guid';
    guid.text = 'item.guid';
    field.appendChild(all);
    field.appendChild(content);
    field.appendChild(summary);
    field.appendChild(title);
    field.appendChild(guid);
    field.style.position = 'absolute';
    field.setAttribute('data-xoffset', 30);
    field.setAttribute('data-yoffset', 100);
    field.style.left = x + 30 + 'px';
    field.style.top = y + 100 + 'px';
    field.style.width = '150px';
    field.name = 'field';

    document.querySelector('#program').appendChild(field);
    this.userinputs.push(field)
    
    this.deco.push(r.text(x + 30, y + 67, 'replace in fields:' ).attr({'text-anchor': 'start'}));

    var textinput = new TextInput(x + 29, y + 37, this);
    this.textinputs.push(textinput);

    var textinput = new TextInput(x + 29, y + 77, this);
    this.textinputs.push(textinput); 
}

function WateredReplaceBlock(x, y) {
    Block.call(this, 1, 1, x, y, 'Replace (structured)', 400, 150);
    this.userinputs[0].style.width = '250px';
    this.userinputs[0].required = true;
    this.userinputs[0].placeholder = 'keyword';
    var userinput = document.createElement('input');
    userinput.type = 'text';
    userinput.style.width = '250px';
    userinput.style.position = 'absolute';
    userinput.setAttribute('data-xoffset', 30);
    userinput.setAttribute('data-yoffset', 60);
    userinput.style.left = x + 30 + 'px';
    userinput.style.top = y + 60 + 'px';
    userinput.name = 'replace';
    userinput.placeholder = 'replacement';
    document.querySelector('#program').appendChild(userinput);
    this.userinputs.push(userinput)

    var userinput = document.createElement('input');
    userinput.style.position = 'absolute';
    userinput.setAttribute('data-xoffset', 30);
    userinput.setAttribute('data-yoffset', 100);
    userinput.style.left = x + 30 + 'px';
    userinput.style.top = y + 100 + 'px';
    userinput.style.width = '350px';
    userinput.name = 'field';
    userinput.placeholder = 'where';
    document.querySelector('#program').appendChild(userinput);
    this.userinputs.push(userinput)
    
    this.deco.push(r.text(x + 30, y + 67, 'replace in fields:' ).attr({'text-anchor': 'start'}));

    var textinput = new TextInput(x + 29, y + 36, this);
    this.textinputs.push(textinput);

    var textinput = new TextInput(x + 29, y + 76, this);
    this.textinputs.push(textinput);
    
    var textinput = new TextInput(x + 29, y + 116, this);
    this.textinputs.push(textinput);

     // Will be called when a block connects to this block. 
    this.autofillInputs = function() {
        const datalist = document.createElement('datalist');
        datalist.id = 'paths' + this.id;
        for (const item of this.autofillData) {
            datalist.appendChild(new Option(item,item));
        }
        oldList = document.querySelector('#paths' + this.id);
        if (oldList != null) {
            oldList.remove()
        }
        document.querySelector('#program').appendChild(datalist);
        this.userinputs[2].setAttribute('list', datalist.id);
        // to init autocomplete on page load:
        this.userinputs[2].dispatchEvent(new Event("blur")) 
    }
}

function ExtractBlock(x, y) {
    Block.call(this, 1, 1, x, y, 'Extract', 240, 150);
    this.userinputs[0].style.width = '150px';
    this.userinputs[0].required = true;
    this.userinputs[0].placeholder = 'selector (required)';
    
    var userinput = document.createElement('input');
    userinput.type = 'text';
    userinput.style.position = 'absolute';
    userinput.setAttribute('data-xoffset', 30);
    userinput.setAttribute('data-yoffset', 60);
    userinput.style.left = x + 30 + 'px';
    userinput.style.top = y + 60 + 'px';
    userinput.style.width = '150px';
    userinput.name = 'attribute';
    userinput.placeholder = 'attribute (optional)';
    document.querySelector('#program').appendChild(userinput);
    this.userinputs.push(userinput)
    
    var userinput = document.createElement('input');
    userinput.type = 'checkbox';
    userinput.style.position = 'absolute';
    userinput.setAttribute('data-xoffset', 30);
    userinput.setAttribute('data-yoffset', 100);
    userinput.style.left = x + 30 + 'px';
    userinput.style.top = y + 100 + 'px';
    userinput.name = 'extract';
    document.querySelector('#program').appendChild(userinput);
    this.userinputs.push(userinput);
    this.deco.push(r.text(x + 50, y + 107, 'Start at item.content' ).attr({'text-anchor': 'start'}));
    
    var userinput = document.createElement('button');
    var icon = document.createElement('img');
    icon.className = "extractorui feather";
    icon.src = "/icons/crosshair.svg";
    userinput.appendChild(icon);
    userinput.style.position = 'absolute';
    userinput.setAttribute('data-xoffset', 180);
    userinput.setAttribute('data-yoffset', 20);
    userinput.style.left = x + 180 + 'px';
    userinput.style.top = y + 20 + 'px';
    userinput.type = 'button';
    var parent = this;
    userinput.addEventListener('click', function() {
        startExtractorUi(parent.inputs[0].from, parent.userinputs[0]);
    });
    this.userinputs.push(userinput);
    
    document.querySelector('#program').appendChild(userinput);
    SVGInject(icon);

    var textinput = new TextInput(x + 29, y + 37, this);
    this.textinputs.push(textinput);

    var textinput = new TextInput(x + 29, y + 77, this);
    this.textinputs.push(textinput);
}

function UniqueBlock(x, y) {
    Block.call(this, 1, 1, x, y, 'Unique', 150, 100);
    this.userinputs[0].type = 'hidden';
}

function TabletojsonBlock(x, y) {
    Block.call(this, 1, 1, x, y, 'Tables to JSON', 150, 100);
    this.userinputs[0].type = 'hidden';
}

function InsertBlock(x, y) {
    Block.call(this, 2, 1, x, y, 'Insert', 150, 125);
    this.userinputs[0].placeholder = 'xpath';
    this.deco.push(r.path('M' + x + ',' + (y + 80) + 'H' + (x + 140) + 'V' + (y + 60) + 'H' + (x + 150) )); 
    this.deco.push(r.path('M' + x + ',' + (y + 15) + 'H' + (x + 75) + 'V' + (y + 80))); 
    this.deco.push(r.path('M' + (x + 70) + ',' + (y + 75) + 'L' + (x + 75) + ',' + (y + 80) + 'L' + (x + 80) + ',' + (y + 75) ));

    var userinput = document.createElement('input');
    userinput.type = 'checkbox';
    userinput.style.position = 'absolute';
    userinput.setAttribute('data-xoffset', 20);
    userinput.setAttribute('data-yoffset', 95);
    userinput.style.left = x + 20 + 'px';
    userinput.style.top = y + 95 + 'px';
    userinput.name = 'block';
    document.querySelector('#program').appendChild(userinput);
    this.userinputs.push(userinput)
    this.deco.push(r.text(x + 40, y + 102, 'Replace content' ).attr({'text-anchor': 'start'}))
}

function TruncateBlock(x, y) {
    Block.call(this, 1, 1, x, y, 'Truncate', 150, 100);
    this.userinputs[0].type = 'number';
    this.userinputs[0].min = '1';
}

function BuilderBlock(x, y) {
    Block.call(this, 4, 1, x, y, 'Build Feed', 170, 260);
    this.userinputs[0].placeholder = "feed title";
    this.deco.push(r.path("M" + (x + 2) + " " + (y + 95) + "H" + (x + 50)  ));
    this.deco.push(r.path("M" + (x + 2) + " " + (y + 130) + "H" + (x + 50)  ));
    this.deco.push(r.path("M" + (x + 2) + " " + (y + 165) + "H" + (x + 50)  ));
    this.deco.push(r.path("M" + (x + 2) + " " + (y + 200) + "H" + (x + 50) ));

    this.deco.push(r.text(x + 12, y + 75, 'Items:' ).attr({'text-anchor': 'start'}));
    this.deco.push(r.text(x + 52, y + 95, 'title' ).attr({'text-anchor': 'start'}));
    this.deco.push(r.text(x + 52, y + 130, 'content*').attr({'text-anchor': 'start', title: 'required'}));
    this.deco.push(r.text(x + 52, y + 165, 'date' ).attr({'text-anchor': 'start'}));
    this.deco.push(r.text(x + 52, y + 200, 'link' ).attr({'text-anchor': 'start'}));

    var textinput = new TextInput(x + 29, y + 37, this);
    this.textinputs.push(textinput);

    var userinput = document.createElement('input');
    userinput.type = 'checkbox';
    userinput.style.position = 'absolute';
    userinput.setAttribute('data-xoffset', 30);
    userinput.setAttribute('data-yoffset', 225);
    userinput.style.left = x + 30 + 'px';
    userinput.style.top = y + 225 + 'px';
    userinput.name = 'block';
    document.querySelector('#program').appendChild(userinput);
    this.userinputs.push(userinput)

    this.deco.push(r.text(x + 50, y + 232, 'Recalculate GUID' ).attr({'text-anchor': 'start'}));
}

function WebhookBlock(x, y) {
    Block.call(this, 0, 1, x, y, 'Webhook', 250, 100);
    this.userinputs[0].value = 'https://www.pipes.digital/hook/' + this.id;
    this.userinputs[0].style.width = '200px';
    this.userinputs[0].readOnly = true;
}

function SortBlock(x, y) {
    Block.call(this, 1, 1, x, y, 'Sort', 200, 100);
    this.userinputs[0].remove();
    var sortorder = document.createElement('select');
    var asc = document.createElement('option');
    asc.value = 'asc';
    asc.text = 'Oldest First | A-Z';
    var desc = document.createElement('option');
    desc.value = 'desc';
    desc.text = 'Newest First | Z-A';
    sortorder.appendChild(desc);
    sortorder.appendChild(asc);
    sortorder.style.position = 'absolute';
    sortorder.setAttribute('data-xoffset', 30);
    sortorder.setAttribute('data-yoffset', 60);
    sortorder.style.left = x + 30 + 'px';
    sortorder.style.top = y + 60 + 'px';
    sortorder.style.width = '150px';
    sortorder.name = 'sortorder';

    var sortitem = document.createElement('select');
    var updated = document.createElement('option');
    updated.value = 'updated';
    updated.text = 'item.updated';
    var published = document.createElement('option');
    published.value = 'published';
    published.text = 'item.published';
    var content = document.createElement('option');
    content.value = 'content';
    content.text = 'item.content';
    var summary = document.createElement('option');
    summary.value = 'summary';
    summary.text = 'item.summary';
    var url = document.createElement('option');
    url.value = 'url';
    url.text = 'item.url';
    var title = document.createElement('option');
    title.value = 'title';
    title.text = 'item.title';
    var guid = document.createElement('option');
    guid.value = 'guid';
    guid.text = 'item.guid';
    sortitem.appendChild(updated);
    sortitem.appendChild(published);
    sortitem.appendChild(content);
    sortitem.appendChild(summary);
    sortitem.appendChild(url);
    sortitem.appendChild(title);
    sortitem.appendChild(guid);
    sortitem.style.position = 'absolute';
    sortitem.setAttribute('data-xoffset', 30);
    sortitem.setAttribute('data-yoffset', 20);
    sortitem.style.left = x + 30 + 'px';
    sortitem.style.top = y + 20 + 'px';
    sortitem.style.width = '150px';
    sortitem.name = 'sortitem';

    this.userinputs[0] = sortitem
    this.userinputs.push(sortorder);
    document.querySelector('#program').appendChild(sortitem);
    document.querySelector('#program').appendChild(sortorder);
}

function PipeBlock(x, y) {
    Block.call(this, 0, 1, x, y, 'Pipe', 200, 75);
    var that = this;
    getAjax('/pipes', function(pipes) {
        var storedPipe = that.userinputs[0].value;
        that.userinputs[0].remove();
        that.userinputs = [];
        pipes = JSON.parse(pipes);
        var userinput = document.createElement('select');
        userinput.style.position = 'absolute';
        userinput.setAttribute('data-xoffset', 30);
        userinput.setAttribute('data-yoffset', 20);
        userinput.style.left = x + 30 + 'px';
        userinput.style.top = y + 20 + 'px';
        userinput.style.width = '150px';
        userinput.name = 'default';

        pipes.forEach(function(elem) {
            if (elem.id != document.querySelector('main').dataset.pipeid) {
                var pipeOption = document.createElement('option');
                pipeOption.value = elem.id; 
                pipeOption.text = elem.title;
                userinput.appendChild(pipeOption)
            }
        });
        if (storedPipe) {
            userinput.value = storedPipe;
        }
        that.userinputs.push(userinput);
        document.querySelector('#program').appendChild(userinput);
    }, function(msg, status) {
        vex.dialog.alert('Error ' + status +'. Could not load existing pipes: ' + msg);
    });
}

function TwitterBlock(x, y) {
    Block.call(this, 0, 1, x, y, 'Tweets', 150, 100);
    this.userinputs[0].placeholder = 'search';
    var textinput = new TextInput(x + 29, y + 37, this);
    this.textinputs.push(textinput);
    this.foreachable = true;
}

function PeriscopeBlock(x, y) {
    Block.call(this, 0, 1, x, y, 'Periscope', 150, 100);
    this.userinputs[0].placeholder = 'user/url';
    var textinput = new TextInput(x + 29, y + 37, this);
    this.textinputs.push(textinput);
    this.foreachable = true;
}

function MixcloudBlock(x, y) {
    Block.call(this, 0, 1, x, y, 'Mixcloud', 150, 100);
    this.userinputs[0].placeholder = 'channel/url';
    var textinput = new TextInput(x + 29, y + 37, this);
    this.textinputs.push(textinput);
    this.foreachable = true;
}

function UstreamBlock(x, y) {
    Block.call(this, 0, 1, x, y, 'Ustream', 150, 100);
    this.userinputs[0].placeholder = 'channel/url';
    var textinput = new TextInput(x + 29, y + 37, this);
    this.textinputs.push(textinput);
    this.foreachable = true;
}

function SpeedrunBlock(x, y) {
    Block.call(this, 0, 1, x, y, 'Speedrun', 150, 100);
    this.userinputs[0].placeholder = 'game/url';
    var textinput = new TextInput(x + 29, y + 37, this);
    this.textinputs.push(textinput);
    this.foreachable = true;
}

function DailymotionBlock(x, y) {
    Block.call(this, 0, 1, x, y, 'Dailymotion', 150, 100);
    this.userinputs[0].placeholder = 'channel/url';
    var textinput = new TextInput(x + 29, y + 37, this);
    this.textinputs.push(textinput);
    this.foreachable = true;
}

function SvtplayBlock(x, y) {
    Block.call(this, 0, 1, x, y, 'SVT Play', 150, 100);
    this.userinputs[0].placeholder = 'program/url';
    var textinput = new TextInput(x + 29, y + 37, this);
    this.textinputs.push(textinput);
    this.foreachable = true;
}

function VimeoBlock(x, y) {
    Block.call(this, 0, 1, x, y, 'Vimeo', 150, 100);
    this.userinputs[0].placeholder = 'channel/url';
    var textinput = new TextInput(x + 29, y + 37, this);
    this.textinputs.push(textinput);
    this.foreachable = true;
}

function TwitchBlock(x, y) {
    Block.call(this, 0, 1, x, y, 'Twitch', 150, 100);
    this.userinputs[0].placeholder = 'user/url';
    var textinput = new TextInput(x + 29, y + 37, this);
    this.textinputs.push(textinput);
    this.foreachable = true;
}

function RedditBlock(x, y) {
    Block.call(this, 0, 1, x, y, 'Reddit', 150, 100);
    this.userinputs[0].placeholder = 'subreddit';
    var textinput = new TextInput(x + 29, y + 37, this);
    this.textinputs.push(textinput);
    this.foreachable = true;
}

function SoundcloudBlock(x, y) {
    Block.call(this, 0, 1, x, y, 'Soundcloud', 200, 125);
    this.userinputs[0].placeholder = 'user';
    this.userinputs[0].style.width = '150px';
    var textinput = new TextInput(x + 29, y + 37, this);
    this.textinputs.push(textinput);
    this.foreachable = true;

    var datatypes = document.createElement('select');
    var all = document.createElement('option');
    all.value = 'all';
    all.text = 'All (except likes)';
    var tracks = document.createElement('option');
    tracks.value = 'tracks';
    tracks.text = 'Tracks';
    var albums = document.createElement('option');
    albums.value = 'albums';
    albums.text = 'Albums';
    var playlists = document.createElement('option');
    playlists.value = 'playlists';
    playlists.text = 'Playlists';
    var reposts = document.createElement('option');
    reposts.value = 'reposts';
    reposts.text = 'Reposts';
    var likes = document.createElement('option');
    likes.value = 'likes';
    likes.text = 'Likes';

    datatypes.appendChild(all);
    datatypes.appendChild(tracks);
    datatypes.appendChild(albums);
    datatypes.appendChild(playlists);
    datatypes.appendChild(reposts);
    datatypes.appendChild(likes);

    datatypes.style.position = 'absolute';
    datatypes.setAttribute('data-xoffset', 30);
    datatypes.setAttribute('data-yoffset', 60);
    datatypes.style.left = x + 30 + 'px';
    datatypes.style.top = y + 60 + 'px';
    datatypes.style.width = '150px';
    datatypes.name = 'datatypes';

    this.userinputs.push(datatypes);
    document.querySelector('#program').appendChild(datatypes);
}

function MergeBlock(x, y) {
    Block.call(this, 2, 1, x, y, 'Merge Items', 150, 100);
    this.userinputs[0].placeholder = 'format';
    var textinput = new TextInput(x + 29, y + 37, this);
    this.textinputs.push(textinput);
}

function ImagesBlock(x, y) {
    Block.call(this, 1, 1, x, y, 'Images', 200, 100);
    this.userinputs[0].type = 'hidden';

    var userinput = document.createElement('button');
    userinput.innerHTML = "Gallery";
    userinput.style.position = 'absolute';
    userinput.setAttribute('data-xoffset', 20);
    userinput.setAttribute('data-yoffset', 20);
    userinput.style.left = x + 55 + 'px';
    userinput.style.top = y + 20 + 'px';
    userinput.type = 'button';
    var parent = this;
    userinput.addEventListener('click', function() {
        startGalleryUi(parent.inputs[0].from, parent);
    });
    this.userinputs.push(userinput);

    document.querySelector('#program').appendChild(userinput);
}


function OutputBlock() {
    x = document.querySelector('#program').clientWidth - 20
    y = document.querySelector('#program').clientHeight / 2
    Block.call(this, 1, 0, x, y, 'Output');
    this.inputs[0].remove();
    this.inputs[0] = new PipeOutput(x, y, this);
    this.userinputs[0].type = 'hidden';
    this.base.hide();
    this.title.hide();
    this.titleEdit.hide();
    this.id = 'output';
    this.inspectorTitle.remove();
}

var compatibleGlows = [];
function isCompatible(from, to) {
    if (from.constructor.name == 'Input' || from.constructor.name == 'PipeOutput') {
        // Be consistent in the order: We always think from output to input, even if users drags an input
        var temp = to;
        to = from;
        from = temp;
    }
    var blockCompatible = true;
    if (from.block.constructor.name == 'DownloadBlock') {
        blockCompatible = (from.block.constructor.name == 'ExtractBlock' || from.block.constructor.name == 'BuilderBlock' || to.block.constructor.name == 'ExtractBlock' || to.block.constructor.name == 'BuilderBlock' || from.constructor.name == 'PipeOutput' || to.constructor.name == 'PipeOutput' || from.constructor.name == 'TextInput' || to.constructor.name == 'TextInput' || from.block.constructor.name == 'ImagesBlock' || to.block.constructor.name == 'ImagesBlock')
    }

    // Water blocks can use regular blocks as input, but not the other way around
    var waterDirection = true;
    if (from.block.constructor.name.startsWith('Water') || to.block.constructor.name.startsWith('Water')) {
       // Either both are water blocks or only the to block is a water block
       waterDirection = ((from.block.constructor.name.startsWith('Water') && to.block.constructor.name.startsWith('Water')) || ((! from.block.constructor.name.startsWith('Water')) && to.block.constructor.name.startsWith('Water')) || to.constructor.name == 'PipeOutput')
    }
    
    
    return (blockCompatible &&
    from
    &&  (
        ((to.constructor.name == 'Input' || to.constructor.name == 'PipeOutput') && from.constructor.name == 'Output')
        ||
        (to.constructor.name == 'TextOutput' && from.constructor.name == 'TextInput')
        ||
        (to.constructor.name == 'TextInput' && from.constructor.name == 'TextOutput')
        )
    && to.block != from.block
    && waterDirection)
}

function unmarkCompatible() {
    if (compatibleGlows) {
        compatibleGlows.forEach(function(elem) {
            elem.remove();
        });
        compatibleGlows = [];
    }
}

function markCompatible(to) {
     if (to.constructor.name == 'Input' || to.constructor.name == 'TextInput' || to.constructor.name == 'PipeOutput') {
        // mark all outputs
        blocks.forEach(function(block) {
            if (block != to.block) {
                block.outputs.forEach(function(output) {
                    if (isCompatible(to, output)) {
                        compatibleGlows.push(output.base.glow({color: 'white' }));
                    }
                });
            }
        });
    } else {
        // mark all inputs
        blocks.forEach(function(block) {
            if (block != to.block) {
                block.inputs.forEach(function(output) {
                    if (isCompatible(to, output)) {
                        compatibleGlows.push(output.base.glow({color: 'white' }));
                    }
                });
                block.textinputs.forEach(function(output) {
                    if (isCompatible(to, output)) {
                        compatibleGlows.push(output.base.glow({color: 'green' }));
                    }
                });
            }
        });
    }
}

var activeConnector = null;
var startGlow = null;
var dragging = false;
function Connector(x, y, block, slot) {
    this.base = r.ellipse(x, y, 15, 15);
    this.base.toBack();
    this.block = block;
    // at which slot of the block this connector is
    this.slot = slot;
    var that = this;

    this.attr = function(props) {
        this.base.attr(props);
    }

    this.transform = function(x, y) {
        this.base.transform(x, y);
    }

    this.getBBox = function() {
        return this.base.getBBox();
    }

    this.remove = function() {
        unconnect(that);
        this.base.remove();
    }

    this.base.click(function() {
        if (activeConnector && activeConnector != this.data('parent') && isCompatible(that, activeConnector)) {
            unconnect(this.data('parent'));
            unconnect(activeConnector);
            if (startGlow) {
                startGlow.remove();
                startGlow == null;
            }
            
            connect(that, activeConnector);
            
            activeConnector.base.animate({"fill-opacity": 0.3}, 500);
            activeConnector = null;
            unmarkCompatible();
        } else {
            if (startGlow) {
                startGlow.remove();
                startGlow = null;
            }
            if (activeConnector) {
                activeConnector.base.animate({"fill-opacity": 0.3}, 500);
            }
            unmarkCompatible();
            if (activeConnector == this.data('parent')) {
                activeConnector = null;
            } else {
                startGlow = that.base.glow({color: 'white' });
                this.animate({"fill-opacity": .6}, 500);
                activeConnector = this.data('parent');
                markCompatible(this.data('parent'));
            }
        }   
    });

    var start = function () {
        if (startGlow) {
            startGlow.remove();
            startGlow = null;
        }
        startGlow = this.glow({color: 'white' });
        
        markCompatible(this.data('parent'));
    },
    move = function (dx, dy, x ,y) {
        if (! dragging) {
            dragging = true;
            this.animate({"fill-opacity": .6}, 500);
        }
        if (this.dragTarget && (r.getElementByPoint(x, y) == null || r.getElementByPoint(x, y).data('parent')  != this.dragTarget)) {
            this.dragTarget = null;
            this.dragGlow.remove();
        }
    },
    end = function () {
        if (dragging) {
            dragging = false;
            unconnect(that);
            unconnect(this.dragTarget);
            if (this.dragTarget) {
                this.dragGlow.remove();
                connect(that, this.dragTarget);
                
            }
            
            startGlow.remove();
            startGlow = null;
            unmarkCompatible();
            
            this.animate({"fill-opacity": 0.3}, 500);
        }
    };
    this.base.drag(move, start, end);
    
    this.base.onDragOver(function(elem) {
        if (elem.data('parent') && isCompatible(elem.data('parent'), this.data('parent'))) {
            if (this.dragGlow) {
                this.dragGlow.remove();
            }
            this.dragGlow = elem.glow({color: 'white' });
            this.dragTarget = elem.data('parent');
        }
    });
}

function Input(x, y, block, slot) {
    Connector.call(this, x, y, block, slot);
    this.base.data('parent', this)
    var that = this;

    this.to = block;
    this.toSlot = slot;
}

function Output(x, y, block, slot) {
    Connector.call(this, x, y, block, slot);
    this.base.data('parent', this)
    var that = this;

    this.from = block;
    this.fromSlot = slot;
}

function TextOutput(x, y, block) {
    Output.call(this, x, y, block);
}

function TextInput(x, y, block) {
    Input.call(this, x, y, block);
    this.base.toFront();
}

function PipeOutput(x, y, block) {
    Input.call(this, x, y, block, 0);
    var color = Raphael.getColor();
    this.base.attr({fill: color, stroke: color, "fill-opacity": 0, "stroke-width": 2, cursor: "grab"});
    this.title = r.text(x, y - 26, 'Out');
    this.title.attr({'font-size': 20});
    this.title.attr({fill: color, stroke: color, cursor: "default"})
    this.glow = this.base.glow({color: 'white' });
    this.glow.attr({opacity: 0 });
}

function getBlock(blockid) {
    if (blockid == 'output') {
        return output;
    }
    return blocks.find(function(elem) {
        return (elem.id == blockid) 
    })
}

/*
 * Put block and connections into a json
 * */
function serialize() {
    var blockOutput = [];
    blocks.forEach(function(elem) {
        var inputOutput = []
        var textinputOutput = []
        for (var i=0;i<elem.inputs.length; i++) {
            if (elem.inputs[i].from) {
                inputOutput.push({from: elem.inputs[i].from.id, from_output_slot: elem.inputs[i].from.outputSlot(elem.id)})
            } else {
                inputOutput.push({})
            }
        }

        for (var i=0;i<elem.textinputs.length; i++) {
            if (elem.textinputs[i].from) {
                textinputOutput.push({from: elem.textinputs[i].from.id, from_output_slot: elem.textinputs[i].from.outputSlot(elem.id)})
            } else {
                textinputOutput.push({})
            }
        }

        var userInputs = [];
        for (var i=0; i < elem.userinputs.length; i++) {
            if (elem.userinputs[i].type == 'checkbox') {
                userInputs.push(elem.userinputs[i].checked);
            } else {
                if (elem.userinputs[i].dataset.value) {
                    userInputs.push(elem.userinputs[i].dataset.value);
                } else {
                    userInputs.push(elem.userinputs[i].value);
                }
            }
        }
        
        blockOutput.push({id: elem.id, type: elem.constructor.name, x: elem.x + elem.startlx, y: elem.y + elem.startly, userinputs: userInputs,
            inputs: inputOutput, textinputs: textinputOutput, name: elem.name
        });
    });
    return {blocks: blockOutput}
}

function createBlock(type, x, y) {
    switch(type) {
        case 'FeedBlock':
            blocks.push(new FeedBlock(x, y));
            break;
        case 'CombineBlock':
            blocks.push(new CombineBlock(x, y));
            break;
        case 'DuplicateBlock':
            blocks.push(new DuplicateBlock(x, y));
            break;
        case 'FilterBlock':
            blocks.push(new FilterBlock(x, y));
            break;
        case 'UniqueBlock':
            blocks.push(new UniqueBlock(x, y));
            break;
        case 'TruncateBlock':
            blocks.push(new TruncateBlock(x, y));
            break;
        case 'SortBlock':
            blocks.push(new SortBlock(x, y));
            break;
        case 'DownloadBlock':
            blocks.push(new DownloadBlock(x, y));
            break;
        case 'ExtractBlock':
            blocks.push(new ExtractBlock(x, y));
            break;
        case 'BuilderBlock':
            blocks.push(new BuilderBlock(x, y));
            break;
        case 'WebhookBlock':
            blocks.push(new WebhookBlock(x, y));
            break;
        case 'ReplaceBlock':
            blocks.push(new ReplaceBlock(x, y));
            break;
        case 'TextinputBlock':
            blocks.push(new TextinputBlock(x, y));
            break;
        case 'PipeBlock':
            blocks.push(new PipeBlock(x, y));
            break;
        case 'TwitterBlock':
            blocks.push(new TwitterBlock(x, y));
            break;
        case 'MergeBlock':
            blocks.push(new MergeBlock(x, y));
            break;
        case 'InsertBlock':
            blocks.push(new InsertBlock(x, y));
            break;
        case 'ForeachBlock':
            blocks.push(new ForeachBlock(x, y));
            break;
        case 'ImagesBlock':
            blocks.push(new ImagesBlock(x, y));
            break;
        case 'ShortenBlock':
            blocks.push(new ShortenBlock(x, y));
            break;
        case 'PeriscopeBlock':
            blocks.push(new PeriscopeBlock(x, y));
            break;
        case 'MixcloudBlock':
            blocks.push(new MixcloudBlock(x, y));
            break;
        case 'UstreamBlock':
            blocks.push(new UstreamBlock(x, y));
            break;
        case 'SpeedrunBlock':
            blocks.push(new SpeedrunBlock(x, y));
            break;
        case 'SoundcloudBlock':
            blocks.push(new SoundcloudBlock(x, y));
            break;
        case 'SvtplayBlock':
            blocks.push(new SvtplayBlock(x, y));
            break;
        case 'DailymotionBlock':
            blocks.push(new DailymotionBlock(x, y));
            break;
        case 'VimeoBlock':
            blocks.push(new VimeoBlock(x, y));
            break;
        case 'TwitchBlock':
            blocks.push(new TwitchBlock(x, y));
            break;
        case 'RedditBlock':
            blocks.push(new RedditBlock(x, y));
            break;
        case 'TabletojsonBlock':
            blocks.push(new TabletojsonBlock(x, y));
            break;
        case 'FilterlangBlock':
            blocks.push(new FilterlangBlock(x, y));
            break;
        case 'WateredFilterBlock':
            blocks.push(new WateredFilterBlock(x, y));
            break;
        case 'WateredDownloadBlock':
            blocks.push(new WateredDownloadBlock(x, y));
            break;
        case 'WateredDuplicateBlock':
            blocks.push(new WateredDuplicateBlock(x, y));
            break;
        case 'WateredReplaceBlock':
            blocks.push(new WateredReplaceBlock(x, y));
            break;
    }
}

/**
 * Get a json from the server, place blocks and connections accordingly
 * */
function unserialize(pipeJson) {
    var pipe = JSON.parse(pipeJson);
    pipe.blocks.forEach(function(block) {
        createBlock(block.type, block.x, block.y);
        if (block.id != 'output') {
            blocks.top().id = block.id;
            if (block.hasOwnProperty('userinput')) { // bc
                blocks.top().userinputs[0].value = block.userinput;
            } else {
                for (var i=0; i < block.userinputs.length; i++) {
                    if (block.userinputs[i] === true) {
                        blocks.top().userinputs[i].checked = 'checked';
                    } else {
                        if (blocks.top().userinputs[i]) {
                            blocks.top().userinputs[i].value = block.userinputs[i];
                        }
                        if (blocks.top().constructor.name == "ForeachBlock") {
                            blocks.top().convert();
                        }
                    }
                }
            }
            if (block.name) {
                blocks.top().setName(block.name);
            }
            styleBlock(blocks.top());
        }
    });

    pipe.blocks.forEach(function(block) {
        block.inputs.forEach(function(input, index) {
            if (input.from) {
                connect(getBlock(input.from).outputs[input.from_output_slot], getBlock(block.id).inputs[index]);
            }
        });
        if (typeof(block.textinputs) != 'undefined') {
            block.textinputs.forEach(function(textinput, index) {
                if (textinput.from) {
                    connect(getBlock(textinput.from).outputs[textinput.from_output_slot], getBlock(block.id).textinputs[index]);
                }
            });
        }
    });
}

function notLoggedIn() {
    return document.querySelector('main').dataset.needlogin != undefined;
}

function showLogin(target) {
    closeExtractorUI();
    var login = '/login';
    if (target && target != undefined) {
        login += '?target=' + target;
    }
    getAjax(login, function(response) {
        vex.dialog.buttons.YES.className = 'hidden';
        vex.dialog.open({ unsafeMessage: response, showCloseButton: false});
    });
}

function postAjax(url, data, success, failure) {
    var params = typeof data == 'string' ? data : Object.keys(data).map(
            function(k){ return encodeURIComponent(k) + '=' + encodeURIComponent(data[k]) }
        ).join('&');

    var xhr = window.XMLHttpRequest ? new XMLHttpRequest() : new ActiveXObject("Microsoft.XMLHTTP");
    xhr.open('POST', url);
    xhr.onreadystatechange = function() {
        if (xhr.readyState>3 && xhr.status==200) { success(xhr.responseText, xhr.status); }
        if (xhr.readyState>3 && xhr.status!=200) { failure(xhr.responseText, xhr.status); }
    };
    xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
    xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
    xhr.send(params);
    return xhr;
}

function getAjax(url, success, failure) {
    var xhr = window.XMLHttpRequest ? new XMLHttpRequest() : new ActiveXObject("Microsoft.XMLHTTP");
    xhr.open('GET', url);
    xhr.onreadystatechange = function() {
        if (xhr.readyState>3) {
            if (xhr.status==200) {
                success(xhr.responseText);
            } else {
                failure(xhr.responseText, xhr.status);
            }
        }
    };
    xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
    xhr.send();
    return xhr;
}

function setFeedLink(pipeid) {
    if (document.querySelector('#outputFeed') == undefined) {
        var a = document.createElement("a");
        a.href = '/feedpreview/' + pipeid;
        a.target = '_blank';
        a.id = 'outputFeed';
        a.title = 'Pipe Output';
        var b = document.createElement("button");
        b.className = 'pure-button';
        var i = document.createElement("img");
        i.src = '/icons/download-cloud.svg';
        SVGInject(i);
        b.appendChild(i);
        a.appendChild(b);
        document.querySelector('#blocks h2').insertAdjacentElement('beforebegin', a);
        
    }
}

function setFeedId(pipeid) {
    document.querySelector('main').dataset.pipeid = pipeid;
}

// save the pipe. If fork is true we also need to move to the forked pipe, otherwise reloads
// would be confusing
function save(fork) {
    var data = {
        pipe: JSON.stringify(serialize()),
        id: document.querySelector('main').dataset.pipeid,
        preview: document.querySelector('#program svg').innerHTML
    }
    document.querySelector('form').reportValidity();
    var saveButton = document.querySelector('#save');
    var origIcon = saveButton.firstChild.cloneNode(true);
    var loader = document.createElement('img');
    loader.src = '/icons/loader.svg';
    
    saveButton.replaceChildren(loader)
    SVGInject(loader);
    
    postAjax('/pipe',
                data,
                function (response) { setFeedId(response); setFeedLink(response); localStorage.setItem('pipeid', response);
                    var successIcon = document.createElement('img');
                    successIcon.src = '/icons/check.svg';

                    saveButton.replaceChildren(successIcon)
                    SVGInject(successIcon);
                    
                    window.setTimeout(function() {
                        saveButton.replaceChildren(origIcon);
                    }, 2000);
                    if (fork) {
                        window.location = "/editor/" + response;
                    }
                },
                function (response) {
                    window.setTimeout(function() {
                        saveButton.replaceChildren(origIcon);
                    }, 2000);
                    vex.dialog.alert({
                                        message: 'Sorry, it seems like you have no space for pipes left.',
                                    })
                }
            );
}
function clear() {
    blocks.forEach(function(elem) {
        if (elem.constructor.name != 'OutputBlock') {
            elem.remove();
        }
    });
}

function load(id, fork) {
    if (fork === true) {
        loaded = true;
        getAjax('/publicpipe/' + id, function(response) {
            unserialize(response);
            flashOutput();
        });
    } else {
        if (notLoggedIn()) {
            showLogin(window.location.pathname);
        } else {
            loaded = true;
            getAjax('/pipe/' + id, function(response) {
                    unserialize(response);
                    flashOutput();
                },
                function(msg, status) { console.log(msg); }
            );
            setFeedLink(id);
            setFeedId(id);
        }
    }
}
    

function flashOutput() {
    if (output.inputs[0].from == undefined) {
        output.inputs[0].glow.attr({opacity: 0.3});
        output.inputs[0].glow.animate({opacity: 0}, 500);
    }
}

var blockBackground = '#E5E5E5';
var titleBackground = '#377b91';
var waterTitleBackground = '#4B814B';
var stroke = '#90B6C2';
var connectorBackground = '#ADD8E6';
var textConnectorBackground = '#90EE90';
var decoColor = 'black';
function styleBlock(block) {
    block.attr({fill: blockBackground, stroke: stroke, "fill-opacity": 1, "stroke-width": 1, cursor: "grab"});
    block.title.attr({fill: 'white', cursor: "grab"});
    block.titleEdit.attr({fill: 'white', cursor: "pointer"});
    if (block.constructor.name.startsWith('Water')) {
        var useTitleColor = waterTitleBackground;
    } else {
        var useTitleColor = titleBackground;
    }
    block.titleBox.attr({"fill-opacity": 1, stroke: stroke, fill: useTitleColor, cursor: "grab"});
    block.deco.forEach(function(elem) {
        elem.attr({'stroke-width': 1});
    });
    block.inputs.forEach(function(elem) {
        elem.attr({fill: connectorBackground, 'stroke-width': 2, "fill-opacity": 0.3});
    });
    if (block.constructor.name == 'TextinputBlock') {
        block.outputs[0].attr({fill: textConnectorBackground, 'stroke-width': 2, "fill-opacity": 0.3});
    } else {
        block.outputs.forEach(function(elem) {
            elem.attr({fill: connectorBackground, 'stroke-width': 2, "fill-opacity": 0.3});
        });
    }
    
    block.textinputs.forEach(function(elem) {
        elem.attr({fill: textConnectorBackground, 'stroke-width': 2, "fill-opacity": 0.3});
    });
    
    block.inspectorTitle.attr({fill: decoColor});
    block.inspector.attr({fill: blockBackground, stroke: titleBackground});

    block.userinputs.forEach(function(userinput) {
        userinput.style.transform = 'translateX(' + - relCanvasX(0) + 'px)';
        userinput.style.transform += ' translateY(' + - relCanvasY(0) + 'px)'
        if (userinput.type != 'checkbox') {
            userinput.style.height += '32px'
        }
    });
}

function dropFeedBlock(pipeid) {
    if (document.querySelector('div[data-pipeid="'+pipeid+'"]')) {
        document.querySelector('div[data-pipeid="'+pipeid+'"]').parentNode.remove();
    }
}

function clear() {
    localStorage.removeItem('pipe');
    localStorage.removeItem('pipeid');
    window.location.href = '/editor';
}

function incrTransform(elem, dx, dy) {
    var oldTranslateX = /translateX\((-*\d+)/.exec(elem.style.transform)
    if (oldTranslateX != null) {
        oldTranslateX = Number(oldTranslateX[1])
    } else {
        oldTranslateX = 0
    }
    var oldTranslateY = /translateY\((-*\d+)/.exec(elem.style.transform)
    if (oldTranslateY != null) {
        oldTranslateY = Number(oldTranslateY[1])
    } else {
        oldTranslateY = 0
    }
    elem.style.transform = 'translateX(' + (oldTranslateX + dx) + 'px)';
    elem.style.transform += ' translateY('+ (oldTranslateY + dy) + 'px)'
    // also, hide elements that are no longer visible. That's necessary to supress the scrolling bar
    if (elem != viewer) {
        var posX = /(\d+)px/.exec(elem.style.left);
        posX = Number(posX[1]);
        var posY = /(\d+)px/.exec(elem.style.top);
        posY = Number(posY[1]);
        var x = posX + oldTranslateX + dx;
        var y = posY + oldTranslateY + dy;

        var main = document.querySelector('main');
        var canvasWidth = main.offsetWidth;
        var canvasHeight = main.offsetHeight;
        
        var pruned = false;
        if (x > canvasWidth) {
            elem.style.display = 'none';
            pruned = true;
        }
        if (x < 0 ) {
            elem.style.display = 'none';
            pruned = true;
        }

         if (y > canvasHeight) {
            elem.style.display = 'none';
            pruned = true;
        }
        if (y < 0 ) {
            elem.style.display = 'none';
            pruned = true;
        }

        if (! pruned) {
            elem.style.display = 'block';
        }
    }
}

var oldState = null;
var timer;
function storeState(block) {
    oldState = block.serialize();
    window.clearTimeout(timer);
    document.querySelector('#undo').classList.add('show');
    document.querySelector('#undo').classList.add('showBlock');
    timer = window.setTimeout(function() {
        hideUndo();
    }, 5000);
}

function restoreState() {
    createBlock(oldState.type, oldState.x, oldState.y);
    for (var i=0; i < blocks.top().userinputs.length; i++) {
        blocks.top().userinputs[i].value = oldState.userinputValues[i];
    }
    blocks.top().id = oldState.id;
    blocks.top().setName(oldState.name);
    styleBlock(blocks.top());
    
    for (var i=0; i < oldState.oldConnections.length; i++) {
        var from = getBlock(oldConnections[i].fromId);
        var to = getBlock(oldConnections[i].toId);
        unconnect(from.outputs[oldConnections[i].fromSlot]);
        unconnect(to.inputs[oldConnections[i].toSlot]);
        connect(from.outputs[oldConnections[i].fromSlot], to.inputs[oldConnections[i].toSlot]);
    }
    hideUndo();
    oldState = null;
}

function hideUndo() {
    window.clearTimeout(timer);
    document.querySelector('#undo').classList.remove('show');
    timer =  window.setTimeout(function() {
        document.querySelector('#undo').classList.remove('showBlock');
    }, 600);
}

// Load an overlay with the content from the given block, which will be a download block.
// The user can create a selector in that overlay, which will be returned to the extractor
// block that startet this UI.
function startExtractorUi(block, extractSelector) {
    var url = '/block/' + block.id;
    var data = {
        pipe: JSON.stringify(serialize())
    }
    
    // init overlay
    var overlay = document.createElement('div');
    overlay.id = 'overlay';

    var button = document.createElement('button');
    button.id = 'overlayclose';
    var close = document.createElement('img');
    close.src = '/icons/x-square.svg';
    button.appendChild(close);
    button.addEventListener('click', function() {
        this.parentNode.remove();
    });

    overlay.appendChild(button);

    var selectorForm = document.createElement('div');
    selectorForm.id = "selectorForm";

    var selector = document.createElement('input');
    selector.id = "selector";
    selector.name = "selector";
    selector.placeholder = "CSS Selector";
    
    var button = document.createElement('button');
    button.id = "selectorSubmit";
    button.type = "button";
    button.innerHTML = "OK";

    button.addEventListener('click', function() {
        extractSelector.value = document.querySelector('#selector').value;
        closeExtractorUI();
    });
    
    selectorForm.appendChild(selector);
    selectorForm.appendChild(button);
    overlay.appendChild(selectorForm);


    // load content of block into overlay via iframe, see https://stackoverflow.com/a/51167233/2508518
    var iframe = document.createElement('iframe');
    iframe.src = 'javascript:void(0);';

    postAjax(url, data, function(response) {
            iframe.contentWindow.document.open();
            iframe.contentWindow.document.write(response);
            iframe.contentWindow.document.close();

            // init all the element picker functionality
            iframe.addEventListener('load', function() {
                var head = iframe.contentWindow.document.head;
                var link = iframe.contentWindow.document.createElement('link');
                link.type = 'text/css';
                link.rel = 'stylesheet';
                link.href = "/pipes-select-style.css";
                head.appendChild(link);

                var script = iframe.contentWindow.document.createElement('script');
                script.src = "/select.js";
                head.appendChild(script);
                
                script = iframe.contentWindow.document.createElement('script');
                script.src = "/pipes-selector.js";
                head.appendChild(script);
            });
            
           
             
        },
        function(errormsg, code) {
            console.log(code);
            if (code == 401) {
                document.querySelector('#selectorForm').innerHTML = '<div class="overlayerror">Please <a href="#" onclick="showLogin(window.location.pathname);">log in</a> to use this function</div>';
            } else {
                document.querySelector('#selectorForm').innerHTML = '<div class="overlayerror">No result</div>';
            }
        }
    );

    overlay.appendChild(iframe);

    document.querySelector('#program').appendChild(overlay);
    SVGInject(close);
}

function startGalleryUi(inputBlock, block) {
    document.querySelector("html").style.overflow = 'hidden';
    document.querySelector("body").style.overflow = 'hidden';
    
    var url = '/block/' + block.id;
    var data = {
        pipe: JSON.stringify(serialize()),
        input_id: inputBlock.id,
        gallery: true
    }
    
    // init overlay
    var overlay = document.createElement('div');
    overlay.id = 'overlay';
    overlay.style.overflow = 'auto';

    var button = document.createElement('button');
    button.id = 'overlayclose';
    var close = document.createElement('img');
    close.src = '/icons/x-square.svg';
    SVGInject(close);
    button.appendChild(close);
    button.addEventListener('click', function() {
        this.parentNode.remove();
    });

    overlay.appendChild(button);

    var selectorForm = document.createElement('div');
    selectorForm.id = "selectorForm";

    var selector = document.createElement('input');
    selector.id = "selector";
    selector.name = "selector";
    selector.placeholder = "CSS Selector";
    
    var button = document.createElement('button');
    button.id = "selectorSubmit";
    button.type = "button";
    button.innerHTML = "OK";

    button.addEventListener('click', function() {
        extractSelector.value = document.querySelector('#selector').value;
        closeExtractorUI();
    });

    // load content of block into overlay via iframe, see https://stackoverflow.com/a/51167233/2508518
    var gallery = document.createElement('div');

    postAjax(url, data, function(response) {
            gallery.innerHTML = response;
        },
        function(errormsg, code) {
            console.log(code);
            if (code == 401) {
                document.querySelector('#selectorForm').innerHTML = '<div class="overlayerror">Please <a href="#" onclick="showLogin(window.location.pathname);">log in</a> to use this function</div>';
            } else {
                document.querySelector('#selectorForm').innerHTML = '<div class="overlayerror">No result</div>';
            }
        }
    );

    overlay.appendChild(gallery);

    document.querySelector('#program').appendChild(overlay);
    SVGInject(close);
    
}

function closeExtractorUI() {
    var overlay = document.querySelector('#overlay');
    if (overlay) {
        overlay.remove();
        document.querySelector("html").style.overflow = 'visible';
        document.querySelector("body").style.overflow = 'visible';
    }
    
}

var loaded=false;
var el;
var r;
var connections;
var blocks=[];
var mouseX;
var mouseY;
var output;
var viewer;
window.onload = function() {
    r = Raphael("program", '100%', '100%');
        connections = [],
        blocks = [];

    output = new OutputBlock();
    blocks.push(output);

    var pipeToLoad = document.querySelector('#program').dataset.pipeid;
    var pipeToFork = document.querySelector('#program').dataset.forkid;
    var fork = false;
    if (pipeToFork != undefined) {
        fork = true;
    }

    if (fork) {
        load(pipeToFork, fork);
    } else {
        if (pipeToLoad != undefined) {
            load(pipeToLoad);
        } else {
            var pipeJson = localStorage.getItem('pipe');
            if (pipeJson) {
                unserialize(pipeJson);
                var pipeid = localStorage.getItem('pipeid')
                if (pipeid) {
                    setFeedId(pipeid)
                    setFeedLink(pipeid)
                    dropFeedBlock(pipeid)
                }
            }
        }
    }
    
    if (! loaded) {
        flashOutput();
    }

    // Make the canvas dragable
    interact(r.canvas)
        .draggable({
            inertia: false,
            restrict: {
                restriction: 'parent',
            },
            onmove: function(evt) {
                var target = evt.target,
                x = (parseFloat(target.getAttribute('data-x')) || 0) - evt.dx,
                y = (parseFloat(target.getAttribute('data-y')) || 0) - evt.dy;
                
                r.setViewBox(x, y, document.querySelector('main').offsetWidth,  document.querySelector('main').offsetHeight, true);
                blocks.forEach(function(block, index) {
                    block.userinputs.forEach(function(elem, index) {
                        incrTransform(elem, evt.dx, evt.dy)                            
                    });
                });

                incrTransform(viewer, evt.dx, evt.dy)
                
                target.setAttribute('data-x', x);
                target.setAttribute('data-y', y);
            }
        })
        .actionChecker(function (pointer, evt, action, interactable, element, interaction) {
            if (r.getElementByPoint(evt.clientX, evt.clientY) == null) {
                return action;
            }
            return false;
        })
        .styleCursor(false);

    var clone = null;
    interact('.blockDragger')
      .draggable({
        // disable inertial throwing
        inertia: false,
        restrict: {
          endOnly: true,
          elementRect: { top: 0, left: 0, bottom: 1, right: 1 }
        },
        // enable autoScroll
        autoScroll: true,
        onstart: function (evt) {
            clone = evt.target.cloneNode(true);
            evt.target.parentNode.insertAdjacentElement('afterbegin', clone);
            evt.target.style.position = 'fixed';    // keep button visible over the canvas
        },
        // call this function on every dragmove event
        onmove: function(evt) {
            var target = evt.target,
            // keep the dragged position in the data-x/data-y attributes
            x = (parseFloat(target.getAttribute('data-x')) || 0) + evt.dx,
            y = (parseFloat(target.getAttribute('data-y')) || 0) + evt.dy;

            // translate the element, corrected for the sidebar scrollbar position (needed because
            // element has position fixed)
            target.style.webkitTransform =
            target.style.transform =
              'translate(' + (x - 150) + 'px, ' + (y - document.querySelector('#blocks').scrollTop)  + 'px)';

            // update the posiion attributes
            target.setAttribute('data-x', x);
            target.setAttribute('data-y', y);
        },
        // call this function on every dragend event
        onend: function (evt) {
            var data = evt.target.dataset.id,
            navHeight = document.querySelector('nav').offsetHeight;
            
            evt.target.style.webkitTransform =
            evt.target.style.transform = 'translate(0px, 0px)';
            evt.target.setAttribute('data-x', 0);
            evt.target.setAttribute('data-y', 0);

            programHeight = document.querySelector('#program').offsetHeight;

            if (evt.pageX > 200 && evt.pageY < (programHeight + 50)) {
                var type = data.replace('Dragger', 'Block');
                type = type.charAt(0).toUpperCase() + type.slice(1);
                createBlock(type, relCanvasX(evt.pageX), relCanvasY(evt.pageY) - navHeight)
                styleBlock(blocks.top());
            }
            evt.target.style.position = 'relative';
            clone.remove();
        }
    })
    .styleCursor(false);

    document.querySelector('#save').addEventListener('click', function() {
        localStorage.setItem('pipe', JSON.stringify(serialize()));
        if (notLoggedIn()) {
            showLogin();
        } else {
            save(fork);
        }
        
    });

    try {
        document.querySelector('#loginlink').addEventListener('click', function(evt) {
            evt.preventDefault();
            localStorage.setItem('pipe', JSON.stringify(serialize()));
            showLogin(window.location.pathname);
        });
    } catch (TypeError) {
    }

    document.querySelector('#new').addEventListener('click', function() {
        vex.dialog.confirm({
            message: 'Start from scratch and lose unsaved changes?',
            callback: function (value) {
                if (value === true) {
                    clear();
                }
            }
        })
    });

    document.querySelector('#blocks').addEventListener('click', function(evt) {
        if (evt.target.classList.contains('info')) {
            vex.dialog.alert({
                unsafeMessage: evt.target.dataset.doc
            });
        }
        if (evt.target.classList.contains('infoicon')) {
            vex.dialog.alert({
                unsafeMessage: evt.target.parentNode.dataset.doc
            });
        }
        if (evt.target.nodeName == 'SUMMARY') {
            if (localStorage.getItem(evt.target.parentNode.id) == 'open') {
                localStorage.setItem(evt.target.parentNode.id, 'closed');
            } else {
                localStorage.setItem(evt.target.parentNode.id, 'open');
            }
        }
        if (evt.target.classList.contains('tab-control')) {
            evt.preventDefault();
            evt.target.closest('details').open = true;
            document.querySelectorAll('#blocks .tab-control').forEach(
                (elem) => elem.classList.remove('pure-button-active')
            );
            evt.target.classList.add('pure-button-active');
        }
    });
    
    document.querySelector('#inspectorClose').addEventListener('click', function(evt) {
            viewer.style.display = 'none';
            getBlock(viewer.dataset.controller).inspector.animate({"fill-opacity": 1}, 500);
        }
    );

    viewer = document.querySelector('#inspector');

    if (window.location.hash.substring(1) == 'save') {
        save(fork);
    }
    
    if (window.location.hash.substring(1) == 'new') {
        clear();
    }

    if (localStorage.getItem('menuInputs') == 'open') {
        document.querySelector('#menuInputs').open = true;
    }

    if (localStorage.getItem('menuManipulate') == 'open') {
        document.querySelector('#menuManipulate').open = true;
    }
    
    if (localStorage.getItem('menuControl') == 'open') {
        document.querySelector('#menuControl').open = true;
    }
    
    if (localStorage.getItem('menuCreate') == 'open') {
        document.querySelector('#menuCreate').open = true;
    }
    
    if (localStorage.getItem('menuIntegrations') == 'open') {
        document.querySelector('#menuIntegrations').open = true;
    }

    document.addEventListener("keyup", function(event) {
        if (event.ctrlKey && event.keyCode == 90 && document.activeElement.tagName !== "INPUT") {
            restoreState()
        }
    });
};
