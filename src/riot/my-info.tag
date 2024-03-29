import SelectInfoStore      from "Store/SelectInfoStore"

<my-info>
  <div class="container-fluid">
    <div if={!metadata}>
      <h3>Select sample or topic.</h3>
    </div>
    <div if={has_sample_id()} class="row-metadata">
      <div class="row">
        <div class="col-xs-12">
          <h3>Sample metadata</h3>
        </div>
      </div>
      <div class="row">
        <div class="col-xs-4 col-lg-12">
          <h4> Sample ID: </h4> {metadata.sample_id}
        </div>
        <div class="col-xs-4 col-lg-12">
          <div if={ metadata.sample_name }>
            <h4> Sample Name: </h4> {metadata.sample_name}
          </div>
        </div>
        <div class="col-xs-4 col-lg-12">
          <div if={ metadata.project_id }>
            <h4> Project ID: </h4> {metadata.project_id}
          </div>
        </div>
      </div>
      <div class="row" if={ metadata.sample_mdb_url && metadata.sample_ncbi_url }>
        <div class="col-xs-6">
          <h4> MicrobeDB.jp: </h4> 
          <a href={metadata.sample_mdb_url} target="_blank">Link</a>
        </div>
        <div class="col-xs-6">
          <h4> NCBI: </h4> 
          <a href={metadata.sample_ncbi_url} target="_blank">Link</a>
        </div>
      </div>
    </div>
    <div if={has_topic_id()} class="row-metadata">
      <div class="row">
        <div class="col-xs-12">
          <h3>Topic metadata</h3>
        </div>
      </div>
      <div class="row">
        <div class="col-xs-12">
          <h4> Topic ID: </h4> {metadata.topic_id}
          <h6> License: </h6> {metadata.license}
          <h6> Attribution: </h6> {metadata.attribution}
          <h6> Source: </h6> 
          <a href={metadata.image_url} target="_blank">Link</a>
        </div>
      </div>
    </div>
    <div class="row row-chart">
      <div class="col-xs-6">
        <div id="taxon_chart" if={taxon_list}>
          <h3>Taxa</h3>
          <my-bar data={taxon_list} element_name={taxon_element_name} chart_id="taxon_bar_chart" color={taxon_color} width={bar_width} height={bar_height}></my-bar>
        </div>
      </div>
      <div class="col-xs-6">
        <div id="topic_chart" if={topic_list}>
          <h3>Topics</h3>
          <my-bar data={topic_list} element_name={topic_element_name} chart_id="topic_bar_chart" color={topic_color} width={bar_width} height={bar_height}></my-bar>
        </div>
        <div id="word_chart" if={word_list}>
          <h3>Words</h3>
          <ul class="list-group">
            <li each={word in word_list} class="list-group-item">{word.word}</li>
          </ul>
        </div>
      </div>
    </div>
  </div>

  <style scoped>
    .container-extend {
      height:100%;
    }
  </style>

  <script>
    var self = this;
    self.bar_width = 0 ;
    self.bar_height = 0 ;

    self.on("mount", ()=>{
      self.topic_element_name = "topic_id" ;
      self.taxon_element_name = "taxonomy_name" ;
    });

    // Acquire topic_id - color relationship
    fetch("http://snail.nig.ac.jp/leaapi/topic/location")
      .then((response) => response.json())
      .then((json) => {
        let color = json.topic_list.reduce((object, d, index) => {
          object[d.topic_id] = d.color ;
          return object
        }, {})
        self.topic_color = color ;
      }) ;

    // Acquire taxon - color relationship
    fetch("http://snail.nig.ac.jp/leaapi/taxonomy/color")
      .then((response) => response.json())
      .then((json) => {
        let color = json.taxonomy_list.reduce((object, d, index) => {
          object[d.taxonomy_name] = d.color ;
          return object
        }, {})
        self.taxon_color = color ;
      }) ;

    // method which determine property status
    self.has_project_id = () => self.metadata.hasOwnProperty("project_id") ;

    self.has_sample_id  = () => self.metadata.hasOwnProperty("sample_id") ;

    self.has_topic_id   = () => self.metadata.hasOwnProperty("topic_id") ;

    self.bar_chart_size = () => {
      let content_height = d3.select(".content").node().getBoundingClientRect().height ;
      let metadata_height = d3.select(".row-metadata").node().getBoundingClientRect().height ;
      let title_height = 26 ;
      let bar_height = content_height - metadata_height - title_height ;

      let content_width = d3.select(".content").node().getBoundingClientRect().width; 
      let bar_width = content_width / 2 ;

      return [bar_width, bar_height];
    } ;

    SelectInfoStore.on(SelectInfoStore.ActionTypes.changed, ()=>{
      self.metadata = {}
      self.metadata = SelectInfoStore.select_info;
      if(self.has_sample_id()){
        delete self.word_list ;
        if(self.has_project_id()){
          d3.queue()
            .defer(d3.json, `http://snail.nig.ac.jp/leaapi/newsample/${self.metadata.project_id}/${self.metadata.sample_id}/taxonomies/genus`)
            .defer(d3.json, `http://snail.nig.ac.jp/leaapi/newsample/${self.metadata.project_id}/${self.metadata.sample_id}/topics`)
            .awaitAll((error, result) => {
              if (error) throw error

              let taxon = result[0]
              let topic = result[1]

              self.update()

              let bar_size = self.bar_chart_size() ;
              self.bar_width = bar_size[0] ;
              self.bar_height = bar_size[1] ;

              self.taxon_list = {}
              self.taxon_list[self.metadata.sample_id] = taxon.taxonomy_list ;

              self.topic_list = {}
              self.topic_list[self.metadata.sample_id] = topic.topic_list ;

              self.update();
            }) ;
        }else{
          d3.queue()
            .defer(d3.json, `http://snail.nig.ac.jp/leaapi/sample/${self.metadata.sample_id}/metadata`)
            .defer(d3.json, `http://snail.nig.ac.jp/leaapi/sample/${self.metadata.sample_id}/taxonomies/genus`)
            .defer(d3.json, `http://snail.nig.ac.jp/leaapi/sample/${self.metadata.sample_id}/topics`)
            .awaitAll((error, result) => {
              if (error) throw error

              let metadata = result[0]
              let taxon = result[1]
              let topic = result[2]

              self.metadata["sample_name"] = metadata.metadata.SampleName;
              self.metadata["sample_ncbi_url"] = `http://ncbi.nlm.nih.gov/sra/${self.metadata.sample_id}`;
              self.metadata["sample_mdb_url"] = `http://microbedb.jp/MDB/search/?q1=${self.metadata.sample_id}&q1_cat=sample&q1_param_srs_id=${self.metadata.sample_id}` ;
              self.update()

              let bar_size = self.bar_chart_size();
              self.bar_width = bar_size[0] ;
              self.bar_height = bar_size[1] ;

              self.taxon_list = {} ;
              self.taxon_list[self.metadata.sample_id] = taxon.taxonomy_list ;

              self.topic_list = {} ;
              self.topic_list[self.metadata.sample_id] = topic.topic_list ;

              self.update();
            }) ;
        }
      }else if(self.has_topic_id()){
        delete self.topic_list ;
        d3.queue()
          .defer(d3.json, `http://snail.nig.ac.jp/leaapi/topic/${self.metadata.topic_id}/metadata`)
          .defer(d3.json, `http://snail.nig.ac.jp/leaapi/topic/${self.metadata.topic_id}/taxonomies/genus`)
          .defer(d3.json, `http://snail.nig.ac.jp/leaapi/topic/${self.metadata.topic_id}/words?n_word_limit=15`)
          .awaitAll((error, result) => {
            if (error) throw error

            let metadata = result[0]
            let taxon = result[1]
            let words = result[2]

            self.metadata["attribution"] = metadata.metadata.Attribution ;
            self.metadata["image_url"] = metadata.metadata.ImageURL ;
            self.metadata["license"] = metadata.metadata.License ;

            self.update()

            let bar_size = self.bar_chart_size();
            self.bar_width = bar_size[0] ;
            self.bar_height = bar_size[1] ;
            let elem_height = 42 ;
            let word_num = parseInt(self.bar_height) / elem_height - 1 ;

            self.taxon_list = {}
            self.taxon_list['' + self.metadata.topic_id] = taxon.taxonomy_list ;

            self.word_list = words.word_list.slice(0,word_num) ;

            self.update();
          });
      }
    });
  </script>
</my-info>
