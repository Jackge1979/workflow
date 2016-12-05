InstanceReadOnlyTemplate = {};

InstanceReadOnlyTemplate.afSelectUser = """
	<input readonly name="{{name}}" id="{{atts.id}}" class="{{atts.class}}" disabled value='{{value}}'/>
"""

# TODO 优化获取字段值的方式, 对各种不同类型字段显示进行处理(eg：日期本地化，checkbox值显示)，支持子表字段类型
InstanceReadOnlyTemplate.afFormGroup = """
	<div class='form-group'>
		{{#with getField this.name}}
			{{#if equals type 'section'}}
					<div class='section callout callout-default'>
						<label class="control-label">{{code}}</label>
						<p>{{{description}}}</p>
					</div>
			{{else}}
				{{#if equals type 'table'}}
					<div class="panel panel-default steedos-table">
						<div class="panel-body" style="padding:0px;">
						  	<div class="panel-heading" >
								<label class='control-label'>{{getLabel code}}</label>
							</div>
							<div style="padding:0px;overflow-x:auto;">
								  <table type='table' class="table table-bordered table-condensed autoform-table" style='margin-bottom:0px;' {{this.atts}} id="{{this.code}}Table" data-schema-key="{{this.name}}">
									  <thead id="{{this.name}}Thead" name="{{this.name}}Thead">
											{{{getTableThead this}}}
									  </thead>
									  <tbody id="{{this.name}}Tbody" name="{{this.name}}Tbody">
											{{{getTableBody this}}}
									  </tbody>
								  </table>
							</div>
						</div>
					</div>
				{{else}}
					{{#if showLabel}}
						<label>{{getLabel code}}</label>
					{{/if}}
					<div class='{{getCfClass this}} form-control' readonly disabled>{{{getValue code}}}</div>
				{{/if}}
			{{/if}}
		{{/with}}
	</div>
"""

InstanceReadOnlyTemplate.imageSign = """
	<img src="{{imageURL user}}" class="image-sign" />
"""

InstanceReadOnlyTemplate.create = (tempalteName, steedosData) ->
	template = InstanceReadOnlyTemplate[tempalteName]

	templateCompiled = SpacebarsCompiler.compile(template, {isBody: true});

	templateRenderFunction = eval(templateCompiled);

	Template[tempalteName] = new Blaze.Template(tempalteName, templateRenderFunction);
	Template[tempalteName].steedosData = steedosData
	Template[tempalteName].helpers InstanceformTemplate.helpers


InstanceReadOnlyTemplate.init = (steedosData) ->
	InstanceReadOnlyTemplate.create("afSelectUser", steedosData);
	InstanceReadOnlyTemplate.create("afFormGroup", steedosData);
	InstanceReadOnlyTemplate.create("imageSign", steedosData);

#TODO 国际化  table字段显示；日期、日期时间字段本地化；checkbox字段值国际化问题；邮件、url、textear 类型显示问题
InstanceReadOnlyTemplate.getValue = (instance, fields, code, locale, utcOffset) ->
	field = fields.findPropertyByPK("code", code)
	value = instance.values[code];

	if locale.toLocaleLowerCase() == 'zh-cn'
		locale = "zh-CN"

	switch field.type
		when 'email'
			value = if value then '<a href=\'mailto:' + value + '\'>' + value + '</a>' else ''
		when 'url'
			value = if value then '<a href=\'http://' + value + '\' target=\'_blank\'>http://' + value + '</a>' else ''
		when 'group'
			if field.is_multiselect
				value = instance.values[code]?.getProperty("fullname").toString()
			else
				value = instance.values[code]?.fullname
		when 'user'
			if field.is_multiselect
				value = instance.values[code]?.getProperty("name").toString()
			else
				value = instance.values[code]?.name
		when 'password'
			value = '******'
		when 'checkbox'
			if instance.values[code] && instance.values[code] != 'false'
				value = TAPi18n.__("form_field_checkbox_yes", {}, locale)
			else
				value = TAPi18n.__("form_field_checkbox_no", {}, locale)
		when 'dateTime'
			if value && value.length == 16
				t = value.split("T")
				t0 = t[0].split("-");
				t1 = t[1].split(":");

				year = t0[0];
				month = t0[1];
				date = t0[2];
				hours = t1[0];
				seconds = t1[1];

				value = new Date(year, month - 1, date, hours, seconds)
			else
				value = new Date(value)
			value = moment(value).utcOffset(utcOffset, true).format("YYYY-MM-DD HH:mm");
		when 'input'
			if field.is_textarea
				value = Spacebars.SafeString(Markdown(value))

	return value;

InstanceReadOnlyTemplate.getLabel = (fields, code) ->
	field = fields.findPropertyByPK("code", code)

	if field.name
		return field.name
	else
		return field.code


InstanceReadOnlyTemplate.getInstanceFormVersion = (instance)->
	form = db.forms.findOne(instance.form);

	form_version = {}

	form_fields = [];

	if form.current._id == instance.form_version
		form_version = form.current
	else
		form_version = _.where(form.historys, {_id: instance.form_version})[0]

	form_version.fields.forEach (field)->
		if field.type == 'section'
			form_fields.push(field);
			if field.fields
				field.fields.forEach (f) ->
					form_fields.push(f);
		else if field.type == 'table'
			field['sfields'] = field['fields']
			delete field['fields']
			form_fields.push(field);
		else
			form_fields.push(field);

	form_version.fields = form_fields;

	return form_version;

InstanceReadOnlyTemplate.getFlowVersion = (instance)->
	flow = db.flows.findOne(instance.flow);
	flow_version = {}
	if flow.current._id == instance.flow_version
		flow_version = flow.current
	else
		flow_version = _.where(flow.historys, {_id: instance.flow_version})[0]

	return flow_version;

#Meteor.startup ->
#	if Meteor.isServer
#		InstanceReadOnlyTemplate.init()