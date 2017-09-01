$(document).ready(function(){
	$('#select-tumour').selectize({
		options: [
			//format {type:'',cell:''},
			{type:'WB',cell:'WB WBC'},	{type:'WB',cell:'WB MNC'}, 	{type:'WB',cell:'WB Gran'},
			{type:'WB',cell:'WB CD3-'},	{type:'WB',cell:'WB CD15-'},{type:'WB',cell:'WB CD19+'},
			
			{type:'BM',cell:'BM WBC'},	{type:'BM',cell:'BM MNC'},	{type:'BM',cell:'BM Gran'},
			{type:'BM',cell:'BM CD34+'},{type:'BM',cell:'BM CD34-'}],
						
			placeholder: 'Tumour material',
			valueField: 'cell',
			labelField: 'cell',
			searchField: ['type'],
			highlight: false,
			selectOnTab: true,
			closeAfterSelect: true,
			hideSelected: true,
			create: false,
			openOnFocus: false,
			delimiter: ",",
	});
	$('#select-constitutional').selectize({
		options: [
			//format {type:'',cell:''},
			{type:'WB',cell:'WB MNC'},	{type:'WB',cell:'WB Gran'},	{type:'WB',cell:'WB CD3+'},
			{type:'WB',cell:'WB T cells'},	{type:'WB',cell:'WB cultured T cells'}, {type:'WB',cell:'WB CD3-'},
			{type:'WB',cell:'WB CD15+'}, {type:'WB',cell:'WB CD19-'},
			
			{type:'BUCCAL',cell:'Buccal'}],
			
			placeholder: 'Constitutional material',
			valueField: 'cell',
			labelField: 'cell',
			searchField: ['type'],
			highlight: false,
			selectOnTab: true,
			closeAfterSelect: true,
			hideSelected: true,
			create: false,
			openOnFocus: false,
			delimiter: ",",
	})
	
	var tumour_select = [0].selectize;
	
	$('#defaultSelect').on('change', function() {
		setDefaults();
	});
	
});	

function setDefaults() {
	var mpn_tumour = ['WB Gran','BM WBC'];
	var mpn_const = ['Buccal','WB T cells','WB cultured T cells'];
	var mds_tumour = ['BM WBC','WB Gran'];
	var mds_const = ['Buccal','WB T cells'];
	var myeloid_tumour = ['BM WBC','WB MNC'];
	var myeloid_const = ['Buccal'];
	var b_lpd_tumour = ['WB CD19+','WB WBC','WB CD15-'];
	var b_lpd_const = ['WB CD15+','Buccal'];
	var lymphoid_tumour = ['BM WBC','WB WBC'];
	var lymphoid_const = ['Buccal'];
	
	var default_selected = document.getElementById('defaultSelect').value;
	tumour_select = $('#select-tumour')[0].selectize;
	const_select = $('#select-constitutional')[0].selectize;
	
	tumour_select.clear();
	const_select.clear();
	
	if (default_selected == 'MPN') {
		for (var i = 0; i < mpn_tumour.length; i++) {
			tumour_select.addItem(mpn_tumour[i]);
		}
		for (var j = 0; j < mpn_const.length; j++) {
			const_select.addItem(mpn_const[j]);
		}
	} else if (default_selected == 'MDS') {
		for (var i = 0; i < mds_tumour.length; i++) {
			tumour_select.addItem(mds_tumour[i]);
		}
		for (var j = 0; j < mds_const.length; j++) {
			const_select.addItem(mds_const[j]);
		}
	} else if (default_selected == 'Other myeloid') {
		for (var i = 0; i < myeloid_tumour.length; i++) {
			tumour_select.addItem(myeloid_tumour[i]);
		}
		for (var j = 0; j < myeloid_const.length; j++) {
			const_select.addItem(myeloid_const[j]);
		}
	} else if (default_selected == 'B-LPD') {
		for (var i = 0; i < b_lpd_tumour.length; i++) {
			tumour_select.addItem(b_lpd_tumour[i]);
		}
		for (var j = 0; j < b_lpd_const.length; j++) {
			const_select.addItem(b_lpd_const[j]);
		}
	} else if (default_selected == 'Other lymphoid') {
		for (var i = 0; i < lymphoid_tumour.length; i++) {
			tumour_select.addItem(lymphoid_tumour[i]);
		}
		for (var j = 0; j < lymphoid_const.length; j++) {
			const_select.addItem(lymphoid_const[j]);
		}
	}

}

function showhide(id) {
	//inactivate summary elements
	var element_summary = document.getElementById('summary');
    element_summary.style.display = 'none';
	var element_summary_tab = document.getElementById('summary_tab');
	element_summary_tab.className = 'tab';
	//inactivate details elements
	var element_details = document.getElementById('details');
    element_details.style.display = 'none';
	var element_details_tab = document.getElementById('details_tab');
	element_details_tab.className = 'tab';
	//activate specified elements
	var element = document.getElementById(id);
    element.style.display = 'block';
	var element_tab = document.getElementById(id + '_tab');
	element_tab.className = 'tab is-tab-selected';
	return
}
