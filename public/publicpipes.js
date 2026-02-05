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
    document.querySelector('#pipes').addEventListener('click', function(evt) {
        if (evt.target.classList.contains('likesymbol')) {
            var target = evt.target.parentNode.parentNode;
            
            var xhr = window.XMLHttpRequest ? new XMLHttpRequest() : new ActiveXObject("Microsoft.XMLHTTP");
            if (evt.target.classList.contains('liked')) {
                xhr.open('POST', '/unlike/' + target.parentNode.id );
            } else {
                xhr.open('POST', '/like/' + target.parentNode.id );
            }
            xhr.onreadystatechange = function() {
                if (xhr.readyState>3 && xhr.status==200) { location.reload(); }
            };
            xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
            xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
            xhr.send();
        }
    });

    try {
        document.querySelector('#loginlink').addEventListener('click', function(evt) {
            evt.preventDefault();
            showLogin(window.location.pathname);
        });
    } catch (TypeError) {
    }
}