window.onload = function () {
    document.querySelector('#pipes').addEventListener('click', function(evt) {
        if (evt.target.classList.contains('title') || evt.target.classList.contains('edit')) {
            if (evt.target.classList.contains('title')) {
                var target = evt.target.parentNode;
            } else {
                var target = evt.target.parentNode.parentNode;
            }
            vex.dialog.prompt({
                message: 'Name your pipe:',
                callback: function(response) {
                    if (response) {
                        var xhr = window.XMLHttpRequest ? new XMLHttpRequest() : new ActiveXObject("Microsoft.XMLHTTP");
                        xhr.open('POST', '/pipetitle/' + target.parentNode.id );
                        xhr.onreadystatechange = function() {
                            if (xhr.readyState>3 && xhr.status==200) { location.reload(); }
                        };
                        xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
                        xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
                        xhr.send('title=' + encodeURIComponent(response));
                    }
                }
                
            });
        }

        if (evt.target.classList.contains('delete') || evt.target.classList.contains('deleteicon')) {
            if (evt.target.classList.contains('delete')) {
                var target = evt.target.parentNode;
            } else {
                var target = evt.target.parentNode.parentNode;
            }
            vex.dialog.confirm({
                message: 'Delete Pipe?',
                callback: function(value) {
                    if (value === true) {
                        var xhr = window.XMLHttpRequest ? new XMLHttpRequest() : new ActiveXObject("Microsoft.XMLHTTP");
                        xhr.open('POST', '/deletePipe/' + target.parentNode.id );
                        xhr.onreadystatechange = function() {
                            if (xhr.readyState>3 && xhr.status==200) { location.reload(); }
                        };
                        xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
                        xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
                        xhr.send();
                    }
                }
                
            });
        }
        if (evt.target.classList.contains('tagadd') || evt.target.classList.contains('tagaddicon')) {
            if (evt.target.classList.contains('tagadd')) {
                var target = evt.target.parentNode;
            } else {
                var target = evt.target.parentNode.parentNode;
            }
            vex.dialog.open({
                message: 'Add a new tag:',
                input: '<div class="vex-dialog-input"><input name="tag" class="vex-dialog-prompt-input" placeholder="" value="" list="tags" type="text"></div>',
                callback: function(data) {
                    if (data.tag != undefined) {
                        var xhr = window.XMLHttpRequest ? new XMLHttpRequest() : new ActiveXObject("Microsoft.XMLHTTP");
                        xhr.open('POST', '/addTag/' + target.parentNode.id );
                        xhr.onreadystatechange = function() {
                            if (xhr.readyState>3 && xhr.status==200) { location.reload(); }
                        };
                        xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
                        xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
                        xhr.send('tag=' + encodeURIComponent(data.tag));
                    }
                }
                
            });
        }
        
        if (evt.target.classList.contains('tagremove') || evt.target.classList.contains('tagremoveicon')) {
            if (evt.target.classList.contains('tagremove')) {
                var target = evt.target.parentNode;
            } else {
                var target = evt.target.parentNode.parentNode;
            }
            var tag = target.textContent;
            vex.dialog.confirm({
                message: 'Remove Tag?',
                callback: function(value) {
                    if (value === true) {
                        var xhr = window.XMLHttpRequest ? new XMLHttpRequest() : new ActiveXObject("Microsoft.XMLHTTP");
                        xhr.open('POST', '/removeTag/' + target.parentNode.parentNode.id );
                        xhr.onreadystatechange = function() {
                            if (xhr.readyState>3 && xhr.status==200) { location.reload(); }
                        };
                        xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
                        xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
                        xhr.send('tag=' + encodeURIComponent(tag));
                    }
                }
                
            });
        }
    });
}