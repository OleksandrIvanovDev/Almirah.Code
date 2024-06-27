function openNav() {
    if (document.getElementById("nav_pane").style.visibility == "visible"){
      document.getElementById("nav_pane").style.visibility = "hidden";
    }else{
      document.getElementById("nav_pane").style.visibility = "visible";
    }
  }
  
  function closeNav() {
    document.getElementById("nav_pane").style.visibility = "hidden";
  }
  
  window.onload = (event) => {
    for (var i = 0, n = document.images.length; i < n; i++) 
    {
      elem = document.images[i];
      if (elem.width > 640)
      {
          elem.style.width = "640px";
      }
    }
    if (document.title == "Document Index"){
      document.getElementById('document_tree_menu_item').style.display = "none";
      document.getElementById('home_menu_item').style.display = "block";
      document.getElementById('index_menu_item').style.display = "none";
      if (document.URL.includes('http')){
        document.getElementById("searchInput").style.display = "block";
      }
    }else{
      document.getElementById('home_menu_item').style.display = "none";
      document.getElementById('index_menu_item').style.display = "block";
      if (document.title.includes("Traceability Matrix:")){
        document.getElementById('document_tree_menu_item').style.display = "none";
      } else {
        document.getElementById('document_tree_menu_item').style.display = "block";
      }
    }
    // Scroll a bit to make navigated anchor visible
    //setTimeout(function() {
    //      window.scrollBy({ 
    //      top: -40,
    //      behavior: "smooth"
    //      });
    //  }, 200);
  };
  
  function downlink_OnClick(clicked){
      clicked.style.display = 'none';
      id_parts = clicked.id.split("_");
      required_id = "DLS_" + id_parts[1];
      document.getElementById(required_id).style.display = 'block';
  }
  function coverageLink_OnClick(clicked){
    clicked.style.display = 'none';
    id_parts = clicked.id.split("_");
    required_id = "COVS_" + id_parts[1];
    document.getElementById(required_id).style.display = 'block';  
  }
  
  function navigate_to_home(){
      if (document.title != "Document Index")
      {
          window.location.href = "./../../index.html";
      }else{
          window.location.href = "./index.html";
      }
  }
  
  // Modal window for image zoom
  function image_OnClick(clicked){
  
      var modal = document.getElementById('image_modal_div');
      var modalImg = document.getElementById("modal_image_id");
      var captionText = document.getElementById("modal_image_caption");
  
      modal.style.display = "block";
      modalImg.src = clicked.src;
      captionText.innerHTML = clicked.alt;
  }
  
  function modal_close_OnClick(clicked){
      var modal = document.getElementById('image_modal_div');
      modal.style.display = "none";
  }

  // Navigation Pane Expand/Collapse
  function nav_toggle_expand_list(el, e){
    var children = el.children;
    e.stopPropagation();
    for (var i = 0; i < children.length; i++) {
      var list_item = children[i];
      if (list_item.tagName == "UL"){
        if (list_item.style.display != "none"){
          list_item.style.display = "none";
        }else{
          list_item.style.display = "block";
        }
      }else if (list_item.tagName == "SPAN"){
        list_item.firstChild.classList.toggle("fa-plus-square-o");
      }
    }
  }