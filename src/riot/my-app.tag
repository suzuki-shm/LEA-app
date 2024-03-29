<my-app>

  <div class="container-fluid container-extend">
    <div class="row row-0">
      <div class="col-lg-9 col-sm-12 column-extend">
        <my-map></my-map>
      </div>
      <div class="col-lg-3 col-sm-12 column-extend">
        <my-panel></my-panel>
      </div>
    </div>
  </div>

  <style scoped>
    .row, my-panel, my-map{
      height:100% ;
    }
    .container-extend {
      height:100% ;
      padding:0 ;
    }
    .column-extend {
      height:100% ;
    }
    .row-0 {
      margin-left:0 ;
      margin-right:0 ;
    }
    .row-0>[class*="col-"]{
      padding-left:0 ;
      padding-right:0 ;
    }
  </style>

</my-app>
