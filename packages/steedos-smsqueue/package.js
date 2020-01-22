Package.describe({
	name: 'steedos:smsqueue',
	version: '0.0.4',
	summary: 'steedos smsqueue',
	documentation: null,
	git: ''
});

Package.onUse(function(api) {
	api.versionsFrom('1.0');
	api.use('ecmascript@0.1.6');
	api.use([
		'raix:eventstate@0.0.2',
		'check',
		'mongo',
		'underscore',
		'ejson',
		'random',
		'coffeescript'
	]);

	api.use('mongo', 'server');

	api.use('universe:i18n@1.13.0');
	tapi18nFiles = ['i18n/en.i18n.json', 'i18n/zh-CN.i18n.json'];
	api.addFiles(tapi18nFiles, ['client', 'server']);

	api.addFiles('checkNpm.js', 'server');

	// Common api
	api.addFiles([
		'lib/common/main.js',
	], ['server']);

	// Common api
	api.addFiles([
		'lib/common/sms.js'
	], ['server']);

	// API's
	api.addFiles('lib/server/api.js', 'server');

	// STARTUP
	api.addFiles('server/startup.coffee', 'server');

	api.export('SMSQueue', ['server']);

});

Package.onTest(function(api) {

});