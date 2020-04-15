window.onload = function () {
    document.querySelector('#settings').addEventListener('click', function(evt) {
        if (evt.target.classList.contains('unsubscribe')) {
            evt.preventDefault()
            var target = evt.target;
            vex.dialog.confirm({
                message: 'Really end your subscription now?',
                callback: function(value) {
                    if (value === true) {
                        var xhr = window.XMLHttpRequest ? new XMLHttpRequest() : new ActiveXObject("Microsoft.XMLHTTP");
                        xhr.open('POST', '/cancelPlan' );
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


    });
}