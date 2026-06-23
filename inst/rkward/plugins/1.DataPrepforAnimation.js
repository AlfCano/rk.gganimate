// this code was generated using the rkwarddev package.
// perhaps don't make changes here, but in the rkwarddev script instead!



function preprocess(is_preview){
	// add requirements etc. here
	echo("require(srvyr)\n");	echo("require(dplyr)\n");
}

function calculate(is_preview){
	// read in variables from dialog


	// the R code to be evaluated

    function getCol(id) {
        var raw = getValue(id);
        if (!raw) return 'NULL';
        if (raw.indexOf('[[') > -1) {
            var inner = raw.split('[[')[1].replace(']]', '');
            return inner.split(String.fromCharCode(34)).join('').split(String.fromCharCode(39)).join('');
        }
        if (raw.indexOf('$') > -1) {
            return raw.split('$')[1];
        }
        return raw;
    }
  

    var svy = getCol('prep_svy');
    if (!svy) return;
    var time = getCol('prep_time');
    var grp = getCol('prep_group');
    var y_var = getCol('prep_y');
    var x_cat = getCol('prep_x_cat');
    var x_lvl = getValue('prep_x_lvl');
    var filter_cond = getValue('prep_filter');
    var save = getValue('prep_save');

    echo("require(srvyr)\n");
    echo("require(dplyr)\n\n");

    echo("cat('Calculating summarized 3D data. This might take a few minutes...\\n')\n");

    echo(save + " <- srvyr::as_survey(" + svy + ") %>%\n");

    if (filter_cond !== '') {
        echo("  dplyr::filter(" + filter_cond + ") %>%\n");
    }

    echo("  dplyr::filter(!is.na(" + time + "), !is.na(" + grp + ")) %>%\n");
    echo("  dplyr::group_by(" + time + ", " + grp + ") %>%\n");
    echo("  dplyr::summarise(\n");
    echo("    bubble_size = srvyr::survey_total(na.rm = TRUE),\n");
    echo("    y_mean = srvyr::survey_mean(" + y_var + ", na.rm = TRUE),\n");
    echo("    x_pct = srvyr::survey_mean(" + x_cat + " == '" + x_lvl + "', na.rm = TRUE) * 100\n");
    echo("  ) %>%\n");
    echo("  dplyr::select(" + time + ", " + grp + ", bubble_size, y_mean, x_pct)\n\n");

    echo("cat('Done! The table " + save + " is ready for rk.gganimate.\\n')\n");
  
}

function printout(is_preview){
	// printout the results
	new Header(i18n("1. Data Prep for Animation results")).print();
echo("rk.header('Animation Data Prep completed')\n");
	//// save result object
	// read in saveobject variables
	var prepSave = getValue("prep_save");
	var prepSaveActive = getValue("prep_save.active");
	var prepSaveParent = getValue("prep_save.parent");
	// assign object to chosen environment
	if(prepSaveActive) {
		echo(".GlobalEnv$" + prepSave + " <- tabla_animacion\n");
	}

}

