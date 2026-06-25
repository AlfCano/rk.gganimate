// this code was generated using the rkwarddev package.
// perhaps don't make changes here, but in the rkwarddev script instead!



function preprocess(is_preview){
	// add requirements etc. here
	echo("require(ggplot2)\n");	echo("require(gganimate)\n");
}

function calculate(is_preview){
	// read in variables from dialog


	// the R code to be evaluated

    function getCol(id) {
        var raw = getValue(id);
        if (!raw) return 'NULL';
        // Divide por corchetes o signos de dólar y filtra espacios vacíos
        var parts = raw.split(/[\[\]\$]+/).filter(Boolean);
        if (parts.length > 0) {
            // Siempre toma la última parte (el verdadero nombre de la columna)
            var last = parts[parts.length - 1];
            // Quita las comillas si las hay
            return last.replace(/["']/g, '');
        }
        return raw;
    }
  

    var df = getValue('inp_df'); if (!df) return;
    var x = getCol('inp_x'); var y = getCol('inp_y'); var time = getCol('inp_time'); var sz = getCol('inp_size'); var col = getCol('inp_color');

    var title = getValue('inp_title'); var sub = getValue('inp_sub'); var xlab = getValue('inp_xlab'); var ylab = getValue('inp_ylab');
    var leg_title = getValue('inp_leg_title');
    var caption = getValue('inp_caption'); // <--- NUEVA LÍNEA AQUÍ

    var pal = getValue('drop_pal'); var theme = getValue('drop_theme'); var show_leg = getValue('chk_legend');
    var base_sz = getValue('spin_base_size'); // NUEVO: Tamaño de fuente

    var story = getValue('chk_story'); var target = getValue('inp_target');

    var fps = getValue('spin_fps'); var dur = getValue('spin_dur'); var w = getValue('spin_w'); var h = getValue('spin_h'); var path = getValue('save_file');

    echo("require(ggplot2)\nrequire(gganimate)\nrequire(gifski)\n\n");

    var aes_call = "x = " + x + ", y = " + y;
    if (sz !== 'NULL') aes_call += ", size = " + sz;
    if (col !== 'NULL') aes_call += ", color = " + col;

    echo("p <- ggplot2::ggplot(" + df + ", ggplot2::aes(" + aes_call + ")) +\n");
    echo("  ggplot2::geom_point(alpha = 0.75, stroke = 1)\n\n");

    if (sz !== 'NULL') {
        echo("p <- p + ggplot2::scale_size(range = c(3, 30), guide = 'none')\n");
    }

    if (col !== 'NULL') {
        echo("\n# Palette Logic for multiple groups\n");
        echo("n_colors <- length(unique(stats::na.omit(" + df + "[['" + col + "']])))\n");
        echo("if(n_colors <= 8) {\n");
        echo("  p <- p + ggplot2::scale_color_brewer(palette = '" + pal + "')\n");
        echo("} else {\n");
        echo("  my_pal <- grDevices::colorRampPalette(RColorBrewer::brewer.pal(8, '" + pal + "'))(n_colors)\n");
        echo("  p <- p + ggplot2::scale_color_manual(values = my_pal)\n");
        echo("}\n\n");
    }

    // LÓGICA DE STORYTELLING (GEOM_LABEL MULTIPLE)
    if (col !== 'NULL' && story === '1' && target !== '') {
        var target_array = target.split(',').map(function(item) {
            return "'" + item.trim() + "'";
        });
        var target_vector = "c(" + target_array.join(', ') + ")";

        echo("# Storytelling: Track specific bubbles\n");
        echo("p <- p + ggplot2::geom_label(\n");
        echo("  ggplot2::aes(label = " + col + "),\n");
        echo("  data = subset(" + df + ", " + col + " %in% " + target_vector + "),\n");
        echo("  vjust = -1.5, size = 5, fontface = 'bold', show.legend = FALSE, alpha = 0.8\n");
        echo(")\n\n");
    }

    // APLICAMOS EL TAMAÑO DE FUENTE DINÁMICO
    echo("p <- p + ggplot2::" + theme + "(base_size = " + base_sz + ")\n");

    if (show_leg !== '1') {
        echo("p <- p + ggplot2::theme(legend.position = 'none')\n");
    }

    var labs_call = [];
    if (title) labs_call.push("title = '" + title + "'");
    if (sub) labs_call.push("subtitle = '" + sub + "'");
    if (xlab) labs_call.push("x = '" + xlab + "'");
    if (ylab) labs_call.push("y = '" + ylab + "'");
    if (caption) labs_call.push("caption = '" + caption + "'"); // <--- NUEVA LÍNEA AQUÍ

    // NUEVO: Lógica inteligente para el título de la leyenda
    if (col !== 'NULL') {
        if (leg_title !== '') {
            // Si el usuario escribió algo, lo usamos
            labs_call.push("color = '" + leg_title + "'");
        } else {
            // Si está vacío, le decimos a R que busque la etiqueta en los metadatos (.rk.meta o variable.label)
            echo("\n# Extraer etiqueta de variable para la leyenda\n");
            echo("col_lbl <- attr(" + df + "[['" + col + "']], 'variable.label')\n");
            echo("if(is.null(col_lbl)) col_lbl <- attr(" + df + "[['" + col + "']], '.rk.meta')[['label']]\n");
            echo("if(is.null(col_lbl)) col_lbl <- '" + col + "'\n");
            labs_call.push("color = col_lbl"); // Sin comillas porque es una variable de R
        }
    }

    if (labs_call.length > 0) {
        echo("p <- p + ggplot2::labs(" + labs_call.join(", ") + ")\n");
    }

    echo("\n# Animation settings\n");
    echo("p <- p + gganimate::transition_time(as.integer(as.character(" + time + "))) +\n");
    echo("  gganimate::ease_aes('linear')\n\n");

    echo("cat('Rendering animation. This may take a minute...\\n')\n");
    echo("anim <- gganimate::animate(p, fps = " + fps + ", duration = " + dur + ", width = " + w + ", height = " + h + ", renderer = gganimate::gifski_renderer())\n");

    var safe_path = path.replace(/\\/g, '/');
    echo("gganimate::anim_save('" + safe_path + "', animation = anim)\n");
  
}

function printout(is_preview){
	// printout the results
	new Header(i18n("2. Animated Bubble Chart results")).print();

    var path = getValue('save_file');
    echo("rk.header('Animated Chart Generated')\n");
    var safe_path = path.replace(/\\/g, '/');
    echo("cat('Animation successfully saved to: " + safe_path + "\\n\\n')\n");
  

}

