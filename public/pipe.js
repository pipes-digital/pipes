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

function showLogin(target) {
    var login = '/login';
    if (target && target != undefined) {
        login += '?target=' + target;
    }
    getAjax(login, function(response) {
        vex.dialog.buttons.YES.className = 'hidden';
        vex.dialog.open({ unsafeMessage: response, showCloseButton: false});
    });
}

window.onload = function () {
    try {
        document.querySelector('#loginlink').addEventListener('click', function(evt) {
            evt.preventDefault();
            showLogin(window.location.pathname);
        });
    } catch (TypeError) {
    }
    
    var id = document.querySelector('#pipe').dataset['id'];
    document.querySelector('#pipe').addEventListener('click', function(evt) {
        if (evt.target.classList.contains('edit')) {
            vex.dialog.prompt({
                message: 'Name your pipe:',
                placeholder: document.querySelector('h2').textContent,
                callback: function(response) {
                    if (response) {
                        var xhr = window.XMLHttpRequest ? new XMLHttpRequest() : new ActiveXObject("Microsoft.XMLHTTP");
                        xhr.open('POST', '/pipetitle/' + id );
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
        if (evt.target.classList.contains('descedit')) {
            var description = document.querySelector('.description').textContent
            vex.dialog.open({
                message: 'Describe your pipe:',
                input: '<div class="vex-dialog-input"><textarea maxlength="800" name="description" class="vex-dialog-prompt-input">' + description + '</textarea></div>',
                callback: function(data) {
                    if (data.description != undefined) {
                        var xhr = window.XMLHttpRequest ? new XMLHttpRequest() : new ActiveXObject("Microsoft.XMLHTTP");
                        xhr.open('POST', '/pipedescription/' + id );
                        xhr.onreadystatechange = function() {
                            if (xhr.readyState>3 && xhr.status==200) { location.reload(); }
                        };
                        xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
                        xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
                        xhr.send('description=' + encodeURIComponent(data.description));
                    }
                }
                
            });
        }
        if (evt.target.classList.contains('sharePipe')) {
             vex.dialog.confirm({
                message: 'Share Pipe?',
                callback: function(value) {
                    if (value === true) {
                        var xhr = window.XMLHttpRequest ? new XMLHttpRequest() : new ActiveXObject("Microsoft.XMLHTTP");
                        xhr.open('POST', '/sharePipe/' + id);
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
        if (evt.target.classList.contains('unsharePipe')) {
            vex.dialog.confirm({
                message: 'Unshare Pipe?',
                callback: function(value) {
                    if (value === true) {
                        var xhr = window.XMLHttpRequest ? new XMLHttpRequest() : new ActiveXObject("Microsoft.XMLHTTP");
                        xhr.open('POST', '/unsharePipe/' + id);
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
        if (evt.target.classList.contains('copyPipe')) {
             vex.dialog.confirm({
                message: 'Duplicate this Pipe?',
                callback: function(value) {
                    if (value === true) {
                        var xhr = window.XMLHttpRequest ? new XMLHttpRequest() : new ActiveXObject("Microsoft.XMLHTTP");
                        xhr.open('POST', '/copyPipe/' + id);
                        xhr.onreadystatechange = function() {
                            if (xhr.readyState>3 && xhr.status==200) { 
                                location.reload();
                                window.location.href = xhr.responseText + "#copied";
                            }
                        };
                        xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
                        xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
                        xhr.send();
                    }
                }
                
            });
        }

         if (evt.target.classList.contains('delete') || evt.target.classList.contains('deleteicon')) {
            vex.dialog.confirm({
                message: 'Delete Pipe?',
                callback: function(value) {
                    if (value === true) {
                        var xhr = window.XMLHttpRequest ? new XMLHttpRequest() : new ActiveXObject("Microsoft.XMLHTTP");
                        xhr.open('POST', '/deletePipe/' + id );
                        xhr.onreadystatechange = function() {
                            if (xhr.readyState>3 && xhr.status==200) { location = '/mypipes' }
                        };
                        xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
                        xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
                        xhr.send();
                    }
                }
                
            });
        }
        if (evt.target.classList.contains('tagadd') || evt.target.classList.contains('tagaddicon')) {
            vex.dialog.open({
                message: 'Add a new tag:',
                input: '<div class="vex-dialog-input"><input name="tag" class="vex-dialog-prompt-input" placeholder="" value="" list="tags" type="text"></div>',
                callback: function(data) {
                    if (data.tag != undefined) {
                        var xhr = window.XMLHttpRequest ? new XMLHttpRequest() : new ActiveXObject("Microsoft.XMLHTTP");
                        xhr.open('POST', '/addTag/' + id );
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
            evt.preventDefault();
            if (evt.target.classList.contains('tagremove')) {
                var target = evt.target.parentNode;
            } else {
                var target = evt.target.parentNode.parentNode;
            }
            var tag = target.textContent;
            console.log(tag);
            vex.dialog.confirm({
                message: 'Remove Tag?',
                callback: function(value) {
                    if (value === true) {
                        var xhr = window.XMLHttpRequest ? new XMLHttpRequest() : new ActiveXObject("Microsoft.XMLHTTP");
                        xhr.open('POST', '/removeTag/' + id );
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