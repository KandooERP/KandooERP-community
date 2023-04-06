var companyName = null;
var MutationObserverCtor;
if (typeof WebKitMutationObserver !== 'undefined') {
  MutationObserverCtor = WebKitMutationObserver;
} else {
  MutationObserverCtor = MutationObserver;
}

if (MutationObserverCtor) {
  var targetNode = document.getElementById('qx-main-layout');
  var config = {childList: true};
  var callback = function(mutationsList, observer) {
    var asideNode = null;
    (mutationsList || []).forEach(function(m) {
      for(var i = 0; i < m.addedNodes.length; i++) {
        var node = m.addedNodes[i];
        if (node.tagName === 'ASIDE') {
          asideNode = node;
        }
      }
    });
    if (asideNode) {
      var container = asideNode.querySelector('.qx-info-area');
      if (container) {
        if (companyName) {
          console.error('>>>Company name set via MutationObserver')
          container.setAttribute('data-company-name', companyName);
        } else {
          container.removeAttribute('data-company-name');
        }
      }
    }
  }
  var observer = new MutationObserver(callback);
  observer.observe(targetNode, config);
  // observer.disconnect();      
}

querix.plugins.frontCallModuleList.kandoocompanyname = {
  setName: function (name) {
    companyName = name;
    var doc = window.top.document;
    var container = doc.querySelector('#qx-main-layout > aside > .qx-info-area');
    if (container) {
      container.setAttribute('data-company-name', name);
    }
  },
  clearName: function () {
    companyName = null;
    var doc = window.top.document;
    var container = doc.querySelector('#qx-main-layout > aside > .qx-info-area');
    if (container) {
      container.removeAttribute('data-company-name');
    }
  }

};