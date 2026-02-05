window.onload = function () {
    document.querySelector('#settings').addEventListener('click', function(evt) {
        if (evt.target.classList.contains('deleteAccount')) {
            evt.preventDefault()
            var target = evt.target;
            vex.dialog.prompt({
                unsafeMessage: 'Please enter <strong>I am sure</strong> to delete the account. This is irreversible.',
                callback: function(response) {
                    console.log(response);
                    if (response == "I am sure") {
                        var xhr = window.XMLHttpRequest ? new XMLHttpRequest() : new ActiveXObject("Microsoft.XMLHTTP");
                        xhr.open('POST', '/deleteAccount' );
                        xhr.onreadystatechange = function() {
                            if (xhr.readyState>3 && xhr.status==200) { window.location.href = '/goodbye'; }
                        };
                        xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
                        xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
                        xhr.send('confirm=' + encodeURIComponent(response));
                    }
                }
            });
        }
    });
}