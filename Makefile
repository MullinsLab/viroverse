.PHONY: test short-test cron etc deploy vendor

etc: cron /etc/logrotate.d/viroverse

cron:
	crontab etc/crontab

/etc/logrotate.d/viroverse: etc/logrotate
	@if [[ `readlink $@` == $(PWD)/$< ]]; then \
		echo "`readlink $@` -> $<"; \
	else \
		echo -e "Please install logrotate config:\n   ln -sv $(PWD)/$< $@"; \
		exit 1; \
	fi

etc/logrotate:
	chmod a+r $<
	chmod a+rx `dirname $<`

test:
	REMOTE_USER=vverse ./vv prove -w t/*.t

deploy:
	scripts/deploy

vendor_js := \
	angular/angular.min.js \
	angular-resource/angular-resource.min.js \
	angular-filter/dist/angular-filter.min.js \
	angular-ui-bootstrap/dist/ui-bootstrap-tpls.js \
	clipboard/dist/clipboard.min.js \
	d3/d3.min.js \
	datalib/datalib.min.js \
	sortablejs/Sortable.min.js \
	upload-list/upload-list.js \
	upload-list/angular-upload-list.js \
	vega/vega.min.js \
	vega-embed/vega-embed.min.js \
	angular-file-model/angular-file-model.js

vendor_css := \
	upload-list/upload-list.css

vendor:
	yarn install
	@cp -fv $(addprefix node_modules/, $(vendor_js)) root/static/javascripts/vendor/
	@cp -fv $(addprefix node_modules/, $(vendor_css)) root/static/stylesheets/vendor/
