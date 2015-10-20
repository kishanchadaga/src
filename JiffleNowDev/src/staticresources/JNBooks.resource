require=(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
(function (process,global,Buffer,__argument0,__argument1,__argument2,__argument3,__filename,__dirname){
initI18n(enLocale["book_meeting"]);
var AttendeeHandler = require('./Attendee/handler');
var MeetingTypeHandler = require('./MeetingType/handler');
var CalendarHandler = require('./Calendar/handler');
var MeetingMakingHandler = require('./MeetingInMaking/handler');
var MeetingViewHandler = require('./MeetingView/handler');
var AccountHandler = require('./SfdcAccount/handler');
var Api = require('common_api');

Handlebars.registerHelper('check_multiselects', function(widget, opts) {
	if (widget == "multiselect_dropdown") {
		return opts.fn(this);
	} else {
		return opts.inverse(this);
	}
});
Handlebars.registerHelper('ifNotDeclined', function(status, askConfirm, opts) {
    if (status !== "declined" && askConfirm) {
        return opts.fn(this);
    } else {
        return opts.inverse(this);
    }
});


$(document).ready(function(){
    var url = Api.ENDPOINTS.fetch_meeting_info;
    if($.urlParam('mode') === 'edit'){
        mode = 'edit';
        url = Api.ENDPOINTS.fetch_edit_meeting_info;
    }
    var promise = Api.fetch({
        url: url
    });
    promise.then(function(response){
        var data = response;
        if(data.hasOwnProperty('data')){
            data = data.data;
        }
        meetingInfo.requestors = data.requestors;
        meetingInfo.selected_requestor = data.selected_requestor;
        meetingInfo.domain_validate_url = data.domain_validate_url;
        meetingInfo.request = $.extend(meetingInfo.request, data.meeting);
        if(mode === 'edit'){
            meetingInfo.request.mode = data.mode;
            meetingInfo.request.showCancel = data.show_cancel_meeting;
        }
        envDetails.currentManagedUser = data.current_managed_user;
        envDetails.currentUser = data.current_user;
        envDetails.companyName = data.companyname;
        if(mode !== 'view') {
            AccountHandler.init();
            AttendeeHandler.init();
            MeetingTypeHandler.init();
            CalendarHandler.init();
            MeetingMakingHandler.init();
        } else {
            MeetingViewHandler.init();
        }

        setupUiI18n();
    });
});



}).call(this,require('_process'),typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {},require("buffer").Buffer,arguments[3],arguments[4],arguments[5],arguments[6],"/app/scripts/Book/app.js","/app/scripts/Book")
},{"./Attendee/handler":3,"./Calendar/handler":8,"./MeetingInMaking/handler":12,"./MeetingType/handler":15,"./MeetingView/handler":17,"./SfdcAccount/handler":19,"_process":28,"buffer":24,"common_api":"common_api"}],2:[function(require,module,exports){
(function (process,global,Buffer,__argument0,__argument1,__argument2,__argument3,__filename,__dirname){
var AttendeeActions = Reflux.createActions([
    'fetchInternal',
    'fetchExternal',
    'selectExternalAttendee',
    'unselectExternalAttendee',
    'selectInternalAttendee',
    'unselectInternalAttendee',
    'searchInternal',
    'searchExternal',
    'eventCreated',
    'tabChanged',
    'roleFilterChosen',
    'removeFilters',
    'filterInternal',
    'filterExternal',
    'createAttendee',
    'editAttendees',
    'canSelectAttendees',
    'updateAreYouAttending',
    'showAttendeesList',
    'unselectAttendee'
]);


module.exports = AttendeeActions;


}).call(this,require('_process'),typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {},require("buffer").Buffer,arguments[3],arguments[4],arguments[5],arguments[6],"/app/scripts/Book/Attendee/actions.js","/app/scripts/Book/Attendee")
},{"_process":28,"buffer":24}],3:[function(require,module,exports){
(function (process,global,Buffer,__argument0,__argument1,__argument2,__argument3,__filename,__dirname){
var AttendeeActions = require('./actions');
var MeetingInMakingActions = require('../MeetingInMaking/actions');
var AttendeeStore = require('./store').AttendeeStore;
var AddEditAttendeeStore = require('./store').AddEditAttendeeStore;
var CalendarEventStore = require('../Calendar/store').CalendarEventStore;
var CalendarAvailabilityStore = require('../Calendar/store').CalendarAvailabilityStore;

var AttendeeHandler = (function () {
    var internalListContainer = $("#internal-attendees-tab").find(".attendees-list");
    var externalListContainer = $("#external-attendees-tab").find(".attendees-list");

    var internalSearchBox = $(".user-search-box");

    var attendeeList = $(".attendees-list");

    var viewAttendeeContainer = $("#attendee-information .modal-body");

    var attendeeModal = $("#attendee-information");

    var attendeeFilterPanel = $("#attendee-filter-panel");
    var attendeeFilterSearch  = $("#attendee-filter-search",attendeeFilterPanel);
    var attendeeFilterRolePanel = $("#attendee-filter", attendeeFilterPanel);
    var addAttendeeForm = $('#add-attendee-form');

    var internalAttendeeTab = $('#internal');
    var externalAttendeeTab = $('#external');
    var defaultAttendeeType = 'internal';
    var addAttendeeBtn = $('#add_attendee');
    var addAttendeePopup = $('#add-attendee-modal');
    var attendingMeeting = $("input[name='attend-meeting']");
    var attendingYes = $("#attend-meeting-yes");
    var statusLine = $("a", 'li.blue-top-align');
    var blueContainer = $("div.blue-container");
    var loggedInUserLabel = $("#logged-in-user-label");
    var notificationModal = $(".notification-modal");
    var name = envDetails.currentUser.first_name + " " + envDetails.currentUser.last_name+", ";

    var isAutoSetByDetails = false;
    var attendeeStatus = {
        enableSave: true,
        message: ""
    };
    var eventInfo = {};
    var selectedTab = "internal";

    var storeHandlers = {
        internal: handleInternalUsers,
        external: handleExternalUsers,
        internalAttendeeUnselected: onInternalAttendeeUnselected,
        externalAttendeeUnselected: onExternalAttendeeUnselected,
        tabChanged: onTabChanged,
        selectionNotPossible: onSelectionNotPossible,
        showAttendeesList: showAttendeesList,
        removeSelf: removeSelf
    };
    var showRemoveStatus = false;

    function removeSelf() {
        if (!showRemoveStatus) {
            statusLine.html('');
            attendingYes.prop('checked', false);
            blueContainer.slideDown();
            AttendeeActions.updateAreYouAttending(null);
            MeetingInMakingActions.updateAreYouAttending(null);
        } else {
            $("#attend-meeting-no").prop('checked', true);
            statusLine.html(i18n.t("you_are_not_attending"));
        }
    }
    function initValidator() {
        $.validator.setDefaults({
            debug: true,
            onfocusout: function(element) {
                if ( !this.checkable( element ) && ( element.name in this.submitted || !this.optional( element ) ) ) {
                    this.element( element );
                }
            },
            messages: {
                first_name: {
                    required: i18n.t("is_required", { attr: i18n.t('first_name') })
                },
                last_name: {
                    required: i18n.t("is_required", { attr: i18n.t('last_name') })
                },
                email: {
                    required: i18n.t("is_required", { attr: i18n.t('email') }),
                    email: i18n.t('invalid_email'),
                },
                contact_no: {
                    required: i18n.t("is_required", { attr: i18n.t('phone') })
                },
                company_name: {
                    required: i18n.t("is_required", { attr: i18n.t('company__placeholder') })
                },
                title: {
                    required: i18n.t('is_required', { attr: i18n.t('title') })
                }
            },
            showErrors: function(errorMap, errorList) {
                for (var i = 0, elements = this.validElements(); elements[ i ]; i++ ) {
                    this.settings.unhighlight.call( this, elements[ i ], this.settings.errorClass, this.settings.validClass );
                    $("#" + elements[ i ].name+ "-error").hide();
                }
                for (var j = 0, errorItem; errorList[ j ]; j++ ) {
                    errorItem = errorList[ j ];
                    this.settings.highlight(errorItem.element);
                    $("#" + errorItem.element.name+ "-error").show();
                    this.showLabel(errorItem.element, errorItem.message);
                };
            }
        })
        addAttendeeForm.validate({
            onsubmit: false,
            onkeyup: false,
            rules: {
                title: {
                    required: true,
                },
                company_name: {
                    required: true
                },
                email: {
                    required: true,
                    email: true,
                    remote: {
                        url: meetingInfo.domainValidateUrl,
                        global: false,
                        data: {
                            type: function() {
                                return selectedTab;
                            }
                        },
                        dataFilter: emailFieldValidatorHandler
                    }
                }
            }
        });
    }
    function init() {
        var eventSystemName = envDetails.urlPrefix;
        initValidator();

        function validateInternalEmailMsg() {
            var emailField = addAttendeeForm.find('#email');
            var text = i18n.t('already_internal_attendee');
            emailField.val("");
            return text;
        }
        AttendeeStore.listen(function(data){
            var func = storeHandlers[data.type];
            if(func) {
                func(data);
            }
        });
        AddEditAttendeeStore.listen(function(data){
            if(data.success){
              AddEditAttendeeStore.resetAttendeeData();
              resetAddAttendeeForm();
              addAttendeePopup.modal('hide');
              if (data.type === 'closePopup') {
                return;
              }
              var user = data.user;
              if (user) {
                updateTotalEntries(data.attendee_type);
                if (data.attendee_type === "internal") {
                    onAttendeeSelected(data, internalListContainer);
                } else {
                    onAttendeeSelected(data, externalListContainer);
                }
              }
            } else {
                var error;
                if (data.error) {
                    error = data.error.errors;
                } else {
                    error = {};
                }
                var validator = addAttendeeForm.validate();
                validator.showErrors(error);
            }
        });
        CalendarEventStore.listen(function(event){
            eventInfo = event.data;
            var html = HandlebarsTemplates['book/filter_attendee_item']({roles:eventInfo.user_filter_options.internal});
            attendeeFilterRolePanel.html(html);

        });
        /* Listening it for SFDC */
        CalendarAvailabilityStore.listen(function(data){
            if(typeof jiffle === 'undefined')
                return;
            if(data.data.resources !== undefined && data.data.resources.external_users.length){
                _.forEach(data.data.resources.external_users, function(external){
                    if(!external.uuid.includes('dummy_')){
                        var selectedUser = externalListContainer.find(".attendee-item[data-email='" + external.email + "']");
                        if(selectedUser.length){
                            selectedUser.data('uuid', external.uuid);
                            selectedUser.find('[data-uuid]').data('uuid', external.uuid);
                        }
                    }
                });
                //SFDC external user uuid updation.
                AttendeeStore.updateExternalSfdcUserUUID(data.data.resources.external_users);
            }
        });
        AttendeeActions.fetchInternal(1);
        AttendeeActions.fetchExternal(1);
        $(internalListContainer).infiniteScroll({
            offset: 200,
            callback: fetchMoreInternalAttendees
        });

        $(externalListContainer).infiniteScroll({
            offset: 100,
            callback: fetchMoreExternalAttendees
        });


        $(internalListContainer).append($("<div/>"));

        internalSearchBox.on('keyup', _.debounce(searchUsers, 369));
        externalListContainer.on('click', '.select-attendee', selectExternalAttendee);
        externalListContainer.on('click', '.unselect-attendee', unselectExternalAttendee);
        internalListContainer.on('click', '.select-attendee', selectInternalAttendee);
        internalListContainer.on('click', '.unselect-attendee', unselectInternalAttendee);
        attendeeFilterRolePanel.on('change', '.filter-checkbox', updateSelectedFilter);
        attendeeFilterPanel.on('click', '.cancel', resetFilter);
        attendeeFilterPanel.on('click', '.apply', applyFilter);
        statusLine.on('click', function(e){
            e.preventDefault();
            e.stopPropagation();
            if (window.isEBCEvent) {
                blueContainer.slideToggle();
            } else {
                blueContainer.slideDown();
            }
        })


        addAttendeeForm.find('input').on('change', function(){
            var validator = addAttendeeForm.validate();
            if(validator.element($(this))){
              AddEditAttendeeStore.updateAttendeeData(this.name, this.value);
            }
        })

        AddEditAttendeeStore.updateAttendeeType(defaultAttendeeType);

        $("#add-attendee-modal").on('show.bs.modal', function(e){
            removeErrors();
            resetAddAttendeeForm();
            $("input#company_name", addAttendeeForm).val(envDetails.companyName);
            updateAttendeeStatus(true, '');
            if(selectedTab === "external") {
                $("#company_name").val("");
            }
            AddEditAttendeeStore.updateAttendeeData('company_name', $("input#company_name").val());

        }).on('hide.bs.modal', function() {
            $.data(addAttendeeForm.find('#email')[0], "previousValue", { old: '', valid: true, message: i18n.t('invalid_domain') });
        });

        addAttendeeBtn.on('click', createAttendee)

        $('a[data-toggle="tab"]').on('shown.bs.tab', function(e){
            var target = $(e.target)[0];
            var type = $(target).attr("id");
            changeTab(type);
            updateSelectedTab(type);
        });

        if(meetingInfo.request) {
            var hasCurrUser = false;
            if (mode === 'new' && meetingInfo.request.users) {
                var currentUserUuid = envDetails.currentUser.uuid;
                var currentUser = _.find(meetingInfo.request.users.internal, function(user) {
                    return user.uuid === currentUserUuid;
                });
                if (currentUser !== undefined) {
                    $("#attend-meeting-yes").prop('checked', true);
                    hasCurrUser = true;
                    statusLine.html(i18n.t("you_are_attending"));
                }
            }
            AttendeeActions.editAttendees(meetingInfo.request.users, hasCurrUser);
        }
        attendingMeeting.on('change', updateAreYouAttending);

    };
    function removeErrors() {
        var validator = addAttendeeForm.validate();

        validator.resetForm();
        validator.reset();
        $(".form-group", addAttendeeForm).removeClass("has-error");
    }

    function changeTab(type) {
        var html = HandlebarsTemplates['book/filter_attendee_item']({roles:eventInfo.user_filter_options[type]});
        attendeeFilterRolePanel.html(html);
        AttendeeActions.tabChanged(type);
    }

    function updateSelectedTab(type) {
        $(".filter-dropdown", '#attendee-filter-panel').removeClass("hide");
        selectedTab = type;
        AddEditAttendeeStore.updateAttendeeType(type);
    }

    function showAttendeesList(data) {
        var type = data.attendeeType;
        updateSelectedTab(type);
        $("a[href='#" + type + "-attendees-tab']").tab("show");
    }

    function updateAttendeeStatus(enableSave, message) {
        attendeeStatus['enableSave'] = enableSave;
        attendeeStatus['message'] = message;
    }
    function emailFieldValidatorHandler(response) {
        var json = JSON.parse(response);
        var errorObj;
        if (selectedTab === "external") {
            if (json.data.domain_type === "internal") {
                if (_.isObject(json.data.user)) {
                    errorObj = {
                        email: i18n.t('already_internal_attendee')
                    };
                } else {
                    errorObj = {
                        email: i18n.t('alert_internal_domain')
                    };
                }
                resetAttendeeDetails();
                updateAttendeeStatus(false, errorObj.email);
            } else {

                if (json.success === false) {
                    errorObj = json.errors;
                    resetAttendeeDetails();
                    updateAttendeeStatus(false, errorObj.email);
                } else {
                    errorObj = {};
                    $("#email-error").css("display", "none");
                    if (_.isObject(json.data.user)) {
                        setAttendeeDetails(json.data.user);
                    }
                }
            }
        } else {
            if (json.success === false) {
                errorObj = json.errors;
                resetAttendeeDetails();
                updateAttendeeStatus(false, errorObj.email);
            } else {
                if (json.data.domain_type === "internal") {
                    errorObj = {};
                    $("#email-error").css("display", "none");
                    if (json.data.user) {
                        setAttendeeDetails(json.data.user);
                    } else {
                        resetAttendeeDetails();
                        updateAttendeeStatus(true, '');
                    }
                } else {
                    errorObj = {
                        email: i18n.t('invalid_domain')
                    };
                    resetAttendeeDetails();
                    updateAttendeeStatus(false, errorObj.email);
                }
            }
        }
        var validator = addAttendeeForm.validate();
            validator.showErrors(errorObj);
        validator.previousValue($("#email")[0]).originalMessage = errorObj.email || '';
        return attendeeStatus.enableSave;
    }
    function setAttendeeDetails(userData) {

        var inputs = addAttendeeForm.find('input[name!=email]');
        inputs.each(function(index, ele) {
            $(ele).prop("readonly", true).val(userData[ele.name]);
            $("#"+ele.name+ "-error").hide();
            AddEditAttendeeStore.updateAttendeeData(ele.name, userData[ele.name]);
        });
        $(".form-group", addAttendeeForm).removeClass("has-error");
        isAutoSetByDetails = true;
    }

    function resetAttendeeDetails() {
        if (isAutoSetByDetails === false) {
            return;
        }
        var inputs = addAttendeeForm.find('input[name!=email]');
        inputs.each(function(index, ele) {
            $(ele).prop("readonly", false).val("");
            AddEditAttendeeStore.updateAttendeeData(ele.name, '');
        });
        if (selectedTab === "internal") {
            $("input#company_name", addAttendeeForm).val(envDetails.companyName);
            AddEditAttendeeStore.updateAttendeeData("company_name", envDetails.companyName);
        }
        isAutoSetByDetails = false;
    }

    function fetchMoreInternalAttendees() {
        var page = $(internalListContainer).data("page") || 1;
        var totalPages = $(internalListContainer).data("total_pages") || 0;
        if(page !== totalPages) {
            AttendeeActions.fetchInternal(page+1);
        }
    }

    function fetchMoreExternalAttendees() {
        var page = $(externalListContainer).data("page") || 1;
        AttendeeActions.fetchExternal(page+1);
    }

    function updateAreYouAttending(e) {
        e.preventDefault();
        e.stopPropagation();

        var value = $(this).data("attending");
        var userUUID = envDetails.currentUser.uuid;
        AttendeeActions.updateAreYouAttending(value);
        MeetingInMakingActions.updateAreYouAttending(value);

        if(value === "yes") {
            AttendeeActions.selectInternalAttendee(userUUID);
            loggedInUserLabel.html(name);
            statusLine.html(i18n.t("you_are_attending"));
        } else {
            showRemoveStatus = true;
            AttendeeActions.unselectInternalAttendee(userUUID);
            loggedInUserLabel.empty();
            statusLine.html(i18n.t("you_are_not_attending"));
        }
        blueContainer.slideUp();
    }
    function createAttendee(e) {
        e.preventDefault();
        e.stopPropagation();
        if (attendeeStatus.enableSave) {
            if (addAttendeeForm.valid()) {
                AttendeeActions.createAttendee();
            }
        } else {
            if (typeof attendeeStatus.message === 'function') {
                attendeeStatus.message();
                addAttendeeForm.modal('hide');
            }
        }
    }

    function resetAddAttendeeForm(){
      addAttendeeForm.find('input').map(function() {
        $(this).prop("readonly", false).val('');
      });
    }

    function searchUsers(e) {
       var value = $(this).val();
       var selectedTab = $(".tabs-attendees li.active").data("search-name");
       if(selectedTab === 'internal')
           AttendeeActions.searchInternal(value);
       else
           AttendeeActions.searchExternal(value);
    }

    function updateContainer(container, data) {
        data.items = _.sortByOrder(data.items, ['available', 'first_name'], [false, true]);
        var html = HandlebarsTemplates['book/attendee_item']({users:data.items});
        container.empty();
        container.append($("<div/>").addClass('selected-attendee'));
        container.append(html);
        attachAttendeeHover(data.items, container);

        moveAddedToTop(container);
        $(container).data("page",data.current_page);
        $(container).data("totalPages", data.total_pages);
    }

    function attachAttendeeHover(users, container) {
        var usersHash = {};
        users.forEach(function(user) {
            usersHash[user.uuid] = user;
        });
        var userTooltipTemplate = HandlebarsTemplates['book/user_tooltip'];
        $('.attendee-item', container).map(function() {
            var userUuid = $(this).data('uuid');
            var userData = usersHash[userUuid];
            $(this).popover({
              html: "true",
              template: "<div class='popover room-tooltip' role='tooltip'><div class='popover-content'></div></div>",
              content: userTooltipTemplate(userData),
              trigger: 'hover',
              placement: 'left'
            })
        });
    }

    function moveAddedToTop(container) {
        var addedElements = $(".added", container);
        addedElements.clone().appendTo($(".selected-attendee", container));
        addedElements.removeClass('added').addClass('hide');
    }

    function handleInternalUsers(data) {
        updateTotalEntries('internal');
        updateContainer(internalListContainer, data.data);
    }

    function updateSelectedFilter(e) {
        var value = $(this).prop("checked");
        var uuid = $(this).data('uuid');
        var selectedTab = $(".tabs-attendees li.active").data("search-name");
        AttendeeActions.roleFilterChosen(uuid, value, selectedTab);
    }

    function resetFilter(e) {
        e.preventDefault();
        var selectedTab = $(".tabs-attendees li.active").data("search-name");
        AttendeeActions.removeFilters(selectedTab);
        $(".filter-checkbox").prop("checked",false);
        $('.filter-dropdown-toggle').dropdown('toggle');
    }

    function applyFilter(e) {
        e.preventDefault();
        var selectedTab = $(".tabs-attendees li.active").data("search-name");
        if(selectedTab === 'internal') {
            AttendeeActions.filterInternal();
        } else {
            AttendeeActions.filterExternal();
        }
        $('.filter-dropdown-toggle').dropdown('toggle');
    }

    function handleExternalUsers(data) {
        updateContainer(externalListContainer, data.data);
    }
    function updateTotalEntries(attendeeType) {
        var count = Object.keys(AddEditAttendeeStore.createdAttendeeHash[attendeeType]).length;
        count += AttendeeStore.totalEntries[attendeeType];
        $("#"+attendeeType+"AttendeeCount").text(count);
    }


    function selectExternalAttendee(e) {
        e.preventDefault();
        e.stopPropagation();
            var user = $(this);
            var uuid = user.data("uuid");

            selectAttendee(user, uuid, externalListContainer);

            AttendeeActions.selectExternalAttendee(uuid);
    }

    function unselectExternalAttendee(e) {
        e.preventDefault();
        e.stopPropagation();
        var user = $(this);
        var uuid = user.data("uuid");

        unselectAttendee(user, uuid, externalListContainer);

        AttendeeActions.unselectExternalAttendee(uuid);
    }

    function selectInternalAttendee(e) {
        e.preventDefault();
        e.stopPropagation();
            var user = $(this);
            var uuid = user.data("uuid");

            selectAttendee(user, uuid, internalListContainer)

            AttendeeActions.selectInternalAttendee(uuid);
    }

    function unselectInternalAttendee(e) {
        e.preventDefault();
        e.stopPropagation();

        var user = $(this);
        var uuid = user.data("uuid");

        unselectAttendee(user, uuid, internalListContainer);

        AttendeeActions.unselectInternalAttendee(uuid);
        $('.attendee-item').popover("hide");
    }

    function selectAttendee(user, uuid, container) {
        var attendeeElement = user.closest('.attendee-item');
        attendeeElement.clone()
            .addClass('added')
                .appendTo($(".selected-attendee", container));
        attendeeElement.addClass('hide');
        setTimeout(function() {
            $('.attendee-item').popover("hide");
        }, 50);
    }

    function unselectAttendee(user, uuid, container) {
        var attendeeElement = $(".attendee-item.hide[data-uuid='" + uuid + "']", container);
        if (attendeeElement.length > 0) {
            user.closest('.attendee-item').remove();
            attendeeElement.removeClass('hide added');
        } else {
            user.closest('.attendee-item')
                .removeClass('added')
                    .appendTo(container);
        }
        setTimeout(function() {
            $('.attendee-item').popover("hide");
        }, 50);
    }

    function onInternalAttendeeUnselected(data) {
        var uuid = data.user && data.user.uuid;
        if (uuid !== envDetails.currentUser.uuid) {
            var user = $(".attendee-item[data-uuid='" + uuid + "']", $(".selected-attendee", internalListContainer));
            unselectAttendee(user, uuid, internalListContainer);
        }

    }

    function onExternalAttendeeUnselected(data) {
        var uuid = data.user && data.user.uuid;
        var user = $(".attendee-item[data-uuid='" + uuid + "']", $(".selected-attendee", externalListContainer));
        unselectAttendee(user, uuid, externalListContainer);
    }

    function onAttendeeSelected(data, container) {
            var user = data.user;
            if (user.uuid === envDetails.currentUser.uuid) {
                MeetingInMakingActions.updateAreYouAttending("yes");
                attendingYes.prop('checked', true);
                statusLine.html(i18n.t("you_are_attending"));
                return;
            }
            var attendeeElement = $('.attendee-item[data-uuid="' + user.uuid + '"]', container);
            if (attendeeElement.length == 0) {
                var html = HandlebarsTemplates['book/attendee_item']({users: [user]});
                attendeeElement = $(html);
            } else {
                attendeeElement.addClass('hide');
                attendeeElement = attendeeElement.clone().removeClass('hide');
            }
            attendeeElement.addClass('added');
            attendeeElement.appendTo($(".selected-attendee", container));

        setTimeout(function() {
            $('.attendee-item').popover("hide");
        }, 50);

    }

    function onSelectionNotPossible(data) {
        notificationModal.notificationModal({
            body: i18n.t("room_overcrowded"),
            dismiss: (data && data.hasCurrUser) ? checkResetUserAttendance : $.noop,
            title: i18n.t('select_attendee_notify_title')
        });
    }

    function checkResetUserAttendance(data) {
        $('input[name=attend-meeting]').prop("checked", false);
        AttendeeActions.updateAreYouAttending(null);
        MeetingInMakingActions.updateAreYouAttending(null);
        statusLine.html('');
        blueContainer.slideDown();
    }



    function onTabChanged(data) {
        internalSearchBox.val(data.searchTerm);
        var filters = data.roles;
        $(".filter-checkbox").prop('checked',false);
        $(".filter-checkbox").each(function(index, cb){
            var uuid = $(cb).data('uuid');
            var hasFilter = filters.indexOf(uuid) > -1;
            $(this).prop('checked', hasFilter);
        });
    }

    return {
        init: init
    }

}());

module.exports = AttendeeHandler;



}).call(this,require('_process'),typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {},require("buffer").Buffer,arguments[3],arguments[4],arguments[5],arguments[6],"/app/scripts/Book/Attendee/handler.js","/app/scripts/Book/Attendee")
},{"../Calendar/store":9,"../MeetingInMaking/actions":10,"./actions":2,"./store":4,"_process":28,"buffer":24}],4:[function(require,module,exports){
(function (process,global,Buffer,__argument0,__argument1,__argument2,__argument3,__filename,__dirname){
var AttendeeActions = require("./actions");
var MeetingTypeActions = require("../MeetingType/actions");
var Api = require('common_api');
var MeetingInMakingActions = require("../MeetingInMaking/actions");

var AttendeeStore = Reflux.createStore({

    init: function () {
        this.listenToMany(AttendeeActions);
        this.internalAttendees = {};
        this.externalAttendees = {};
        this.internalPage = {};
        this.externalPage = {};
        this.fetchingInternal = false;
        this.fetchingExternal = false;
        this.roles = [];
        this.selection = {internal:{},external:{}};
        this.roleFilter = {internal:[], external: []};
        this.canSelect = true;
        this.totalEntries = { internal: {}, external: {} };
        this.editAttendeeStatusHash = { internal: {}, external: {} };
    },

    onShowAttendeesList: function(attendeeType) {
        this.trigger({type: 'showAttendeesList', attendeeType: attendeeType});
    },

    onFetchInternal: function(nextPage, opts) {
        var currentPage = this.internalPage['current_page'] || 0;
        var options = opts || {};
        var perPage = options['per_page'] || 15;
        if(this.fetchingInternal === false && currentPage !== nextPage) {
            this.fetchingInternal = true;
            setTimeout(function() {
                this.fetchingInternal = false
            }.bind(this), 5*1000)
            var totalPages = this.internalPage['total_pages'] || 1000;
            if (currentPage >= totalPages) {
                return;
            }
            var params = {per_page:perPage,page: nextPage, search: this.searchTerm, roles: this.roleFilter.internal};
            if (this.currentEvent) {
                var start = this.currentEvent.start_date.getHours() * 60 + this.currentEvent.start_date.getMinutes();
                var end  = this.currentEvent.end_date.getHours() * 60 + this.currentEvent.end_date.getMinutes();
                params['event_date'] = moment(this.currentEvent.start_date).format("DD-MM-YYYY"),
                params['start_time'] = start;
                params['end_time'] = end;
            }
            if (meetingInfo.request.mode === "edit") {
                params['meeting_request'] = meetingInfo.request.uuid;
            }
            var promise = Api.fetch({
                url: Api.ENDPOINTS.internal_attendees,
                data: params
            });
            promise.then(function(apiResponse){
                this.fetchingInternal = false;
                var currentUserUuid = envDetails.currentUser.uuid;
                this.internalAttendees = this.internalAttendees || {};
                this.selection.internal = this.selection.internal || {};

                this.addAttendeesBatch(this.internalAttendees, this.selection.internal, apiResponse.data.items);
                this.updateSelection(this.internalAttendees, this.selection.internal);

                delete this.internalAttendees[currentUserUuid];
                delete this.selection.internal[currentUserUuid];
                this.internalPage = apiResponse.data;
                var items = this.getAttendeesArray(_.assign({}, this.selection.internal, this.internalAttendees));

                var result = {items: items, current_page: apiResponse.data.current_page, total_pages: apiResponse.data.total_pages };
                this.totalEntries.internal =  Number(apiResponse.data.total_entries)
                this.trigger({type:'internal', data: result, page: apiResponse.data.current_page});
            }.bind(this));

            promise.catch(function(apiResponse){
                console.log(apiResponse.responseJSON.errors);
                this.fetchingInternal = false;
            }.bind(this));
        }
    },

    updateExternalSfdcUserUUID: function(list){
        if(list.length){
            _.forEach(list, function(external){
                if(!external.uuid.includes('dummy_')){
                    var matchedUserKey = _.findKey(this.externalAttendees, { 'email': external.email });
                    var matchedSelectedUserKey = _.findKey(this.selection.external, { 'email': external.email });
                    if(matchedUserKey !== undefined && matchedUserKey.includes('dummy_')){
                        this.externalAttendees[matchedUserKey]['uuid'] = external.uuid;
                        this.externalAttendees[external.uuid] = this.externalAttendees[matchedUserKey];
                        delete this.externalAttendees[matchedUserKey];
                    }
                    if(matchedSelectedUserKey !== undefined && matchedSelectedUserKey.includes('dummy_')){
                        this.selection.external[matchedSelectedUserKey]['uuid'] = external.uuid;
                        this.selection.external[external.uuid] = this.selection.external[matchedSelectedUserKey];
                        delete this.selection.external[matchedSelectedUserKey];
                    }
                }
            }.bind(this));
        }
    },

    getAttendeesArray: function(attendeeHash) {
        var attendeeArr = [];
        if (attendeeHash instanceof Object) {
            for (var attendeeUuid in attendeeHash) {
                attendeeArr.push(attendeeHash[attendeeUuid]);
            }
        }
        return attendeeArr;
    },

    getAttendeeHash: function(attendeeArr) {
        var attendeeHash = {};
        if (attendeeArr instanceof Array) {
            _.forEach(attendeeArr, function(attendee) {
                attendeeHash[attendee.uuid] = attendee;
            });
        }
        return attendeeHash;
    },

    onUnselectAttendee: function(uuid) {
        if (AddEditAttendeeStore.attendee_type === 'internal') {
            this.onUnselectInternalAttendee(uuid);
            if (uuid === envDetails.currentUser.uuid) {
                this.trigger({ type: 'removeSelf' });
            }
        } else {
            this.onUnselectExternalAttendee(uuid);
        }
    },

    addAttendeesBatch: function(allAttendeesHash, selectedAttendeesHash, newAttendeesBatch) {
        _.forEach(newAttendeesBatch, function(attendee) {
            if (typeof selectedAttendeesHash[attendee.uuid] === 'undefined') {
                allAttendeesHash[attendee.uuid] = attendee;
            } else {
                _.assign(selectedAttendeesHash[attendee.uuid], attendee);
            }
        });
    },

    onUpdateAreYouAttending: function(value) {
        // MeetingInMakingActions.updateAreYouAttending(value);
    },

    onFetchExternal: function(nextPage, opts) {
        //done by pvrcs
        if (!window.isEBCEvent) {

            var currentPage = this.externalPage['current_page'] || 0;
            if(this.fetchingExternal == false && currentPage !== nextPage) {
                setTimeout(function(){
                    this.fetchingExternal = false
                }.bind(this), 5*1000)

                this.fetchingExternal = true;
                var totalPages = this.externalPage['total_pages'] || 1000;
                if(currentPage >= totalPages)
                    return;
                var params = {per_page:15,page: nextPage, search: this.externalSearchTerm, roles: this.roleFilter.external};
                if(this.currentEvent) {
                    var start = this.currentEvent.start_date.getHours() * 60 + this.currentEvent.start_date.getMinutes();
                    var end  = this.currentEvent.end_date.getHours() * 60 + this.currentEvent.end_date.getMinutes();
                    params['event_date'] = moment(this.currentEvent.start_date).format("DD-MM-YYYY"),
                    params['start_time'] = start;
                    params['end_time'] = end;
                }
                if(typeof jiffle !== 'undefined'){
                    if(meetingInfo.request.mode === "edit"){
                       params['account_name'] = meetingInfo.request.meeting_with; 
                    }
                    else {
                        params['account_id'] = require("../SfdcAccount/store").selectedAccount.id;
                    } 
                }
                if (meetingInfo.request.mode === "edit") {
                    params['meeting_request'] = meetingInfo.request.uuid;
                }
                var promise = Api.fetch({
                    url: Api.ENDPOINTS.external_attendees,
                    data: params
                });
                promise[((promise.then) ? 'then': 'done')](function(apiResponse){
                    this.fetchingExternal = false;
                    this.addAttendeesBatch(this.externalAttendees, this.selection.external, apiResponse.data.items);
                    this.updateSelection(this.externalAttendees, this.selection.external);
                    this.externalPage = apiResponse.data;
                    var items = this.getAttendeesArray(_.assign({}, this.selection.external, this.externalAttendees));
                    var result = {items: items, current_page: apiResponse.data.current_page, total_pages: apiResponse.data.total_pages};
                    this.trigger({type:'external', data: result, page: apiResponse.data.current_page});
                }.bind(this));

                promise[((promise.catch) ? 'catch': 'fail')](function(apiResponse){
                    console.log(apiResponse.responseJSON.errors);
                    this.fetchingExternal = false;
                }.bind(this));
            }
        }
    },

    onRoleFilterChosen: function(uuid, value, type) {
        var roleFilter = this.roleFilter[type] || [];
        if(value) {
            roleFilter.push(uuid);
        } else {
            _.remove(roleFilter, function(u){
                return uuid === u;
            })
        }
    },

    onRemoveFilters: function(type) {
        this.roleFilter[type] = [];
        if (type === 'internal') {
            this.resetInternalList();
            this.onFilterInternal(1);
        } else {
            this.onFilterExternal(1);
        }
    },

    onSelectInternalAttendee: function(uuid) {

        var user = this.internalAttendees[uuid];
        if (user) {
            user.selected = true;
        } else {
            if (uuid === envDetails.currentUser.uuid) {
                user = envDetails.currentUser;
            }
        }
        this.getOriginalInviteeStatuses(user, 'internal');
        if (!this.selection.internal[uuid]) {
            this.selection.internal[uuid] = user;
            delete this.internalAttendees[uuid];
            this.trigger({type:'internalAttendeeSelected', user: user});
        }

    },
    getOriginalInviteeStatuses: function(user, type) {
        _.assign(user, this.editAttendeeStatusHash[type][user.uuid]);
    },
    getAttendeeCount: function() {
        var internalCount = _.filter(this.selection.internal, function(user) {
            if(user.invite_status && user.invite_status === "declined")
                return false;
            return true;
        }).length;
        var externalCount = _.filter(this.selection.external, function(user) {
            if(user.invite_status && user.invite_status === "declined")
                return false;
            return true;
        }).length;
        return internalCount+externalCount;
    },

    onUnselectInternalAttendee: function(uuid) {
        var user = this.selection.internal[uuid];
        if (user) {
            user.selected = false;
            this.internalAttendees[uuid] = user;
        } else {
            user = { uuid: uuid };
        }

        delete this.selection.internal[uuid]
        var total = Object.keys(this.internalAttendees).length;
        if (total < 15) {
            total = 15;
        }
        this.onFetchInternal(1, {per_page:total});
        this.trigger({type:'internalAttendeeUnselected', user:user});
    },

    onSelectExternalAttendee: function(uuid) {

        var user = this.externalAttendees[uuid];
        if (user) {
            user.selected = true;
            this.getOriginalInviteeStatuses(user, 'external');
        }
        if (!this.selection.external[uuid]) {
            this.selection.external[uuid] = user;
            delete this.externalAttendees[uuid];
            this.trigger({type:'externalAttendeeSelected', user: user});
        }
    },

    onUnselectExternalAttendee: function(uuid) {
        var user = this.selection.external[uuid];
        if (user) {
            user.selected = false;
            this.externalAttendees[uuid] = user;
        } else {
            user = { uuid: uuid };
        }
        delete this.selection.external[uuid]
        var total = Object.keys(this.externalAttendees).length;
        if (total < 15) {
            total = 15;
        }
        this.onFetchExternal(1, {per_page:total});
        this.trigger({type:'externalAttendeeUnselected', user:user});
    },

    onAllExternalAttendeeUnselected: function() {
        if(Object.keys(this.selection.external).length){
            var user = _.cloneDeep(this.selection.external);
            this.selection.external = {};
            this.trigger({type:'allExternalAttendeeUnselected', user:user});
        }
    },

    onTabChanged: function(type) {
        var term = this.searchTerm || '';
        if(type === 'external') {
            term = this.externalSearchTerm || '';
        }
        this.trigger({type:'tabChanged', searchTerm:term, roles: this.roleFilter[type]});
    },

    onEditAttendees: function(attendees, hasCurrUser) {
        if(attendees) {
            var attendeeCount = 0;
            var internalHash = {};
            _.each(attendees.internal, function(a){
                internalHash[a.uuid] = a;
                a.selected = true;
                a.available = true;
                attendeeCount++;
            });
            this.editAttendeeStatusHash.internal = internalHash;

            var externalHash = {};
            _.each(attendees.external, function(a){
                externalHash[a.uuid] = a;
                a.selected = true;
                a.available = true;
                attendeeCount++;
            });
            this.editAttendeeStatusHash.external = externalHash;

            this.selection.internal = this.getAttendeeHash(attendees.internal);
            this.selection.external = this.getAttendeeHash(attendees.external);
            if (attendeeCount > 0) {
                this.trigger({type:'editAttendees', users:attendees, hasCurrUser: hasCurrUser});
            }
        }
    },

    resetInternalList: function() {
        this.internalPage = {};
        this.internalAttendees = {};
    },

    resetExternalList: function() {
        this.externalPage = {};
        this.externalAttendees = {};
    },

    onSearchInternal: function(searchTerm) {
        this.resetInternalList();
        this.searchTerm = searchTerm;
        this.onFetchInternal(1);
    },

    onSearchExternal: function(searchTerm) {
        this.resetExternalList();
        this.externalSearchTerm = searchTerm;
        this.onFetchExternal(1);
    },

    onFilterInternal: function() {
        this.resetInternalList();
        this.onFetchInternal(1);
    },

    onFilterExternal: function() {
        this.resetExternalList();
        this.onFetchExternal(1);
    },

    updateSelection: function(users, selectedUsers) {
        _.forEach(users, function(user, uuid) {
            if (selectedUsers[uuid]) {
                delete users[uuid];
            }
        });
    },

    onEventCreated: function(event) {
        this.currentEvent = event;
        this.resetInternalList();
        this.resetExternalList();
        this.onFetchInternal(1);
        this.onFetchExternal(1);
    },

    onCanSelectAttendees: function(canSelect) {
        this.canSelect = canSelect;
    }

});

var AddEditAttendeeStore = Reflux.createStore({

    init: function() {
        this.listenToMany(AttendeeActions);
        this.attendee_data = {};
        this.attendee_type = 'internal';
        this.createdAttendeeHash = {
            internal: {},
            external: {}
        }
    },

    updateAttendeeData: function(field_name, field_data) {
        this.attendee_data[field_name] = field_data;
    },

    updateAttendeeType: function(type) {
        this.attendee_type = type;
    },

    onCreateAttendee: function() {
        var promise = Api.update({
                        url: Api.ENDPOINTS.user_create,
                        data: {user: this.attendee_data, user_type: this.attendee_type}
                      });
        promise.then(function(data) {
          if(data.success){
            this.addAttendeeData(data.data, true);
          }
        }.bind(this));

        promise.catch(function(response) {
            console.log(response);
            this.trigger({error: response.responseJSON, success: false});
        }.bind(this));
    },

    addAttendeeData: function(data, isNew) {
        var type, user, list_type;

        if (this.attendee_type == 'internal') {
            type = 'internalAttendeeSelected';
            list_type = 'internalAttendees';
        } else {
            type = 'externalAttendeeSelected';
            list_type = 'externalAttendees';
        }

        if (data) {
            user = data.user;
            var currentUserUuid = envDetails.currentUser.uuid;
            user['available'] = true;
            user['selected'] = true;
            var canTrigger = true;
            if (currentUserUuid !== user.uuid) {
                if ( !AttendeeStore.selection[this.attendee_type][user.uuid]) {
                    AttendeeStore.selection[this.attendee_type][user.uuid] = (user);
                    AttendeeStore.updateSelection(AttendeeStore[list_type], AttendeeStore.selection[this.attendee_type]);
                } else {
                    canTrigger = false;
                }
            }
        }

        if (canTrigger)  {
            this.trigger({type: type, user: user, attendee_type: this.attendee_type, success: true, isNewAttendee: isNew});
        } else {
            this.trigger({ type: "closePopup", success: true });
        }
    },

    resetAttendeeData: function(){
        this.attendee_data = {};
    }
});


module.exports = {
  AttendeeStore : AttendeeStore,
  AddEditAttendeeStore : AddEditAttendeeStore
}


}).call(this,require('_process'),typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {},require("buffer").Buffer,arguments[3],arguments[4],arguments[5],arguments[6],"/app/scripts/Book/Attendee/store.js","/app/scripts/Book/Attendee")
},{"../MeetingInMaking/actions":10,"../MeetingType/actions":14,"../SfdcAccount/store":20,"./actions":2,"_process":28,"buffer":24,"common_api":"common_api"}],5:[function(require,module,exports){
(function (process,global,Buffer,__argument0,__argument1,__argument2,__argument3,__filename,__dirname){
var BriefingRequestActions = Reflux.createActions([
    'briefingDetails'
]);

module.exports = BriefingRequestActions;


}).call(this,require('_process'),typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {},require("buffer").Buffer,arguments[3],arguments[4],arguments[5],arguments[6],"/app/scripts/Book/BriefingRequest/actions.js","/app/scripts/Book/BriefingRequest")
},{"_process":28,"buffer":24}],6:[function(require,module,exports){
(function (process,global,Buffer,__argument0,__argument1,__argument2,__argument3,__filename,__dirname){
var BriefingRequestActions = require("./actions");
var Api = require('common_api');

var BriefingRequestStore = Reflux.createStore({

    init: function () {
        this.listenToMany(BriefingRequestActions);
    },
    onBriefingDetails: function() {

        var promise = Api.fetch({
            url: Api.ENDPOINTS.briefing_details.replace('{briefing_uuid}',briefing_uuid)
        });
        promise.then(function(data){
            if(meetingInfo && meetingInfo.request) {
                data.meetingRequest = meetingInfo.request
            }
            this.trigger({success: true, data: data});
        }.bind(this));

        promise.catch(function(error){
            this.trigger({success:false, data: error.responseJSON});
        }.bind(this))
    }
});

module.exports = BriefingRequestStore;


}).call(this,require('_process'),typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {},require("buffer").Buffer,arguments[3],arguments[4],arguments[5],arguments[6],"/app/scripts/Book/BriefingRequest/store.js","/app/scripts/Book/BriefingRequest")
},{"./actions":5,"_process":28,"buffer":24,"common_api":"common_api"}],7:[function(require,module,exports){
(function (process,global,Buffer,__argument0,__argument1,__argument2,__argument3,__filename,__dirname){
var CalendarActions = Reflux.createActions([
    'eventInfo',
    'fetchAvailability',
    'updateCalendar',
    'updateEvent',
    'eventCreated',
    'initialAvailability'
]);


module.exports = CalendarActions;



}).call(this,require('_process'),typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {},require("buffer").Buffer,arguments[3],arguments[4],arguments[5],arguments[6],"/app/scripts/Book/Calendar/actions.js","/app/scripts/Book/Calendar")
},{"_process":28,"buffer":24}],8:[function(require,module,exports){
(function (process,global,Buffer,__argument0,__argument1,__argument2,__argument3,__filename,__dirname){

var Store = require('./store');
var Actions = require('./actions');
var AttendeeActions = require('../Attendee/actions');
var MeetingTypeActions = require('../MeetingType/actions');
var MeetingTypeStore = require('../MeetingType/store');

var BriefingRequestActions = require('../BriefingRequest/actions');
var BriefingRequestStore = require('../BriefingRequest/store');

var MeetingInMakingActions = require('../MeetingInMaking/actions');

var CalendarHandler = (function () {
    var eventData = null;
    var initialAvailability = null;
    var calendarData = null;
    var attendingMeeting = $("input#attend-meeting-no");
    var statusLine = $("a", 'li.blue-top-align');
    var notificationModal = $(".notification-modal");

    var agendaGist = $("#agenda_gist");
    var agendaDetail = $("#agenda_detail");

    function setupStoreListeners() {
        Store.CalendarEventStore.listen(function(data){
           if(data.success) {
               setupCalendar(data.data);
           }
        });
        Store.CalendarAvailabilityStore.listen(onCalendarUpdates);
        Store.CalendarInitialAvailabilityStore.listen(onInitialAvailability);

        BriefingRequestStore.listen(function(response){

            if(response.success) {

               //Display agenda to user
               var requestedBriefingAgenda = response.data.data.custom_fields.custom_info;
               agendaGist[0].innerHTML = requestedBriefingAgenda;
               agendaDetail[0].innerHTML = requestedBriefingAgenda +
                                            '<br/>' + 'Requested Internal Attendees : '
                                            +response.data.data.custom_fields.internal_attendees+
                                            '<br/>' + 'External Attendees : '
                                            +response.data.data.custom_fields.external_attendees;

               MeetingInMakingActions.updateAreYouAttending(false);

               setupBriefingCalendar({ event : response.data.data });
           }
        });
    }

    function setupBriefingCalendar(eventInfo) {
        var data = eventInfo.event;
        eventData = data;

        var startDate = scheduler.date.date_part(moment(data.start_date).utc()._d);
        var endDate = scheduler.date.date_part(moment(data.end_date).utc()._d);

        //Configurations
        scheduler.config.xml_date="%Y-%m-%d %H:%i"; //date format used to parse data from datasets
        scheduler.config.day_date = "%D, %M %j";

        scheduler.config.details_on_create = false;
        var step = 30;
        scheduler.config.hour_size_px=(60/step)*22;
        scheduler.config.icons_select = ['icon_delete'];
        scheduler.config.icons_edit = ['icon_delete'];

        //xy, scheduler's element sizes
        scheduler.xy.nav_height = 0;
        scheduler.xy.min_event_height = 20;

        //Format templates
        setupSchedulerTemplates();

        if(startDate.getTime() == endDate.getTime()){
            scheduler.init('scheduler_here',startDate,"day");
        }
        else{

            setWeekStart(startDate, endDate);
            scheduler.ignore_week = function(date){
                if (date.getTime() < startDate.getTime() || date.getTime() > endDate.getTime())
                    return true;
            };
            scheduler.init('scheduler_here',startDate,"week");
        }

        setupSchedulerListeners();

        setTimeout(function(){
           updateBlocking(data);

            if(meetingInfo.request && meetingInfo.request.start_time) {
                var request = meetingInfo.request;
                var start = new Date(request.start_time);
                var end = new Date(request.end_time);
                request.start_time = new Date(start.getTime()+start.getTimezoneOffset() * 60000);
                request.end_time = new Date(end.getTime()+end.getTimezoneOffset() * 60000);
                scheduler.addEvent({
                    start_date: request.start_time,
                    end_date: request.end_time,
                    text: 'Hello',
                    uuid: request.uuid,
                    // give the id as predefined text to differentiate between new and old event
                    id: "alreadyAddedEvent"
                });
            }

        }, 50);
    }

    function setupCalendar(eventInfo) {
        var data = eventInfo.event;
        eventData = data;
        var startDate = scheduler.date.date_part(moment(data.start_date).utc()._d);
        var endDate = scheduler.date.date_part(moment(data.end_date).utc()._d);
        scheduler.config.now_date = new Date(1970, 1, 1);
        scheduler.config.check_limits = true;
        scheduler.config.collision_limit = 1;
        scheduler.config.start_on_monday = false;
        scheduler.config.day_date = "%D, %M %j";
        scheduler.config.limit_start = scheduler.date.add(startDate, -1, 'day');
        scheduler.config.limit_end = scheduler.date.add(endDate, 1, 'day');
        scheduler.config.limit_view  = true;
        scheduler.config.separate_short_events = true;
        scheduler.config.multi_day = false; // to prevent multiple day event creation.
        scheduler.config.mark_now = false;


        setWeekStart(startDate, endDate);
        hideNonEventDays(startDate, endDate);

        var step = 30;
        scheduler.config.details_on_create = false;
        scheduler.xy.min_event_height = 20;

        scheduler.config.hour_size_px=(60/step)*22;

        scheduler.config.icons_select = ['icon_delete'];
        scheduler.config.icons_edit = ['icon_delete'];


        setupSchedulerTemplates();

        scheduler.xy.nav_height = 0;
        scheduler.config.xml_date="%Y-%m-%d %H:%i";

        scheduler.init('scheduler_here', startDate);
        scheduler.config.dblclick_create = false;

        setupSchedulerListeners();

        setTimeout(function(){
           updateBlocking(data);

            if(meetingInfo.request && meetingInfo.request.start_time) {
                var request = meetingInfo.request;
                var start = new Date(request.start_time);
                var end = new Date(request.end_time);
                request.start_time = new Date(start.getTime()+start.getTimezoneOffset() * 60000);
                request.end_time = new Date(end.getTime()+end.getTimezoneOffset() * 60000);
                scheduler.addEvent({
                    start_date: request.start_time,
                    end_date: request.end_time,
                    text: 'Hello',
                    uuid: request.uuid,
                    // give the id as predefined text to differentiate between new and old event
                    id: "alreadyAddedEvent"
                });
            }

        }, 50);

    }

    function setWeekStart(startDate, endDate) {

        var weekStartIndex;
        if (scheduler.date.getISOWeek(startDate) === scheduler.date.getISOWeek(scheduler.date.add(endDate, 1, "day"))) {
            weekStartIndex = 0;
        } else {
            weekStartIndex = startDate.getDay()
        }
        scheduler.date.week_start = function(date) {
            var shift = date.getDay();
            if (weekStartIndex) {
                if (shift) {
                    shift -= weekStartIndex;
                } else {
                    shift = weekStartIndex;
                }
            }
            return scheduler.date.date_part(scheduler.date.add(date, -1 * shift, "day"));
        };
    }

    function setupSchedulerTemplates() {

        var step = 30;
        var format = scheduler.date.date_to_str("%h:%i %a");

        scheduler.templates.hour_scale = function(date){
            var html="";
            for (var i=0; i<60/step; i++){
                html+="<div style='height:21px;line-height:21px;'>"+format(date)+"</div>";
                date = scheduler.date.add(date,step,"minute");
            }
            return html;
        };

        scheduler.templates.day_scale_date = scheduler.date.date_to_str(scheduler.config.day_date);

        scheduler.templates.event_class = function(start,end,ev){
            return "";
        };

        scheduler.templates.tooltip_text = function(start,end,ev){
            return "";
        };


        scheduler.templates.event_text = function(start,end,ev){
            return '';
        }

        scheduler.templates.event_header = function(start, end, ev) {
            var start = moment(start).format("h:mm");
            var end = moment(end).format("h:mm");
            return start + " - " + end;

        }
    }

    function setupSchedulerListeners() {

        scheduler.attachEvent('onSchedulerReady', function() {
        });


        scheduler.attachEvent("onClick",function(){return true;});


        scheduler.attachEvent('onEventCollision', function(ev, evs){
            // scheduler.deleteEvent(ev.id);
        });


        scheduler.attachEvent("onLimitViolation", function  (id, obj){
        });

        scheduler.attachEvent("onBeforeViewChange", function(old_mode,old_date,mode,date){
            setTimeout(function(){
               updateCalendarView();
            });
            return true;
        });

        scheduler.attachEvent('onBeforeEventCreated', function(event, e) {
            var events = scheduler.getEvents();
            events.forEach(function(event){
                scheduler.deleteEvent(event.id);
            });
            return true;
        });


        scheduler.attachEvent('onEventAdded', function(id, event){
            scheduler.config.scroll_hour = event.start_date.getHours();
            var events = scheduler.getEvents();
            events.forEach(function(e){
                if(e.id !== event.id) {
                    scheduler.deleteEvent(e.id, true);
                }
            });
            if (event !== null) {
                Actions.eventCreated(event);
                AttendeeActions.eventCreated(event);
                MeetingTypeActions.eventCreated(event);
            }
            setTimeout(function() {
                scheduler.updateView();
            }, 50);

        });


        scheduler.attachEvent('onBeforeEventChanged', function(ev, e, is_new, original) {
            scheduler.config.scroll_hour = ev.start_date.getHours();
            if (scheduler.config.offsite_enabled && isCreate) {
                var diff = (new Date(ev.end_date) - new Date(ev.start_date)) / 60 / 1000;
                if ('neither_nor' === setDurations(ev.start_date, ev.end_date, diff) ) {
                    ev.end_date = scheduler.date.add(ev.start_date, scheduler.config.event_duration, "minute");
                }
            }
            var isViolation = scheduler.checkInMarkedTimespan(ev, 'dhx_time_block');
            return !isViolation;
        });

        scheduler.attachEvent('onEventChanged', function(id, event) {
            Actions.eventCreated(event);
            AttendeeActions.eventCreated(event);
            MeetingTypeActions.eventCreated(event);
        });

        scheduler.attachEvent('onBeforeEventDelete', function(id, event) {
            Actions.eventCreated(null);
            AttendeeActions.eventCreated(null);
            MeetingTypeActions.eventCreated(null);
            return true;
        });

        var isCreate = false;
        scheduler.attachEvent('onBeforeDrag', function(id, mode, e) {
            isCreate = mode === 'create';
            return true;
        });
        scheduler.attachEvent("onDragEnd", function() {
            var events = scheduler.getEvents();
            events.forEach(function(e, index) {
                var start = e.start_date;
                var end = e.end_date;
                var silentMsg = i18n.t('room_type');
                var isViolation, message, title;
                var diff = (new Date(end) - new Date(start)) / 60 / 1000;
                if (scheduler.config.offsite_enabled) {
                    silentMsg = setDurations(start, end, diff);
                }
                if (silentMsg === 'neither_nor') {
                    message = i18n.t('try_select_location');
                    title = i18n.t(silentMsg);
                    notificationModal.notificationModal({
                        title: title,
                        body: message,
                        dismiss: function() {
                            scheduler.deleteEvent(e.id);
                        },
                        class: 'red',
                    });
                } else {
                    if (diff < scheduler.config.minimum_duration || diff > scheduler.config.event_duration) {
                        var ed = scheduler.date.add(e.start_date, scheduler.config.event_duration, "minute");
                        var evCopy = {
                            start_date: e.start_date,
                            end_date: ed
                        };

                        if (scheduler.checkInMarkedTimespan(evCopy, 'dhx_time_block')) {
                            isViolation = true;
                            title = i18n.t('calendar_notify_title');
                            message = i18n.t("slot_unavailable");
                        } else {
                            title = i18n.t('meeting_time');
                            if (scheduler.config.minimum_duration < scheduler.config.event_duration) {
                                message = i18n.t("slot_size_invalid", {
                                    min_duration: scheduler.config.minimum_duration,
                                    max_duration: scheduler.config.event_duration,
                                    silentMsg: silentMsg
                                });
                            } else {
                                message = i18n.t("slot_size_exact", {
                                    duration: scheduler.config.minimum_duration,
                                    silentMsg: silentMsg
                                });
                            }
                        }
                        e.end_date = ed;
                        notificationModal.notificationModal({
                            title: title,
                            body: message,
                            dismiss: function() {
                                if (isViolation) {
                                    scheduler.deleteEvent(e.id);
                                } else {
                                    Actions.eventCreated(e);
                                }
                            },
                            class: 'red',
                            timeout: !isViolation
                        });
                    }
                }
                isCreate = false;
                return false;
            });

        });
    }

    function updateBlocking(data) {
        eventData = data;
        setupBlocking();
    }

    function setDurations(stDt, edDt, diff) {
        var silent = i18n.t('room_type');
        if (initialAvailability) {
            var offsites = initialAvailability.offsites;
            var rooms = initialAvailability.rooms;
            var key = moment(stDt).format('YYYY-MM-DD');
            var startValue = stDt.getHours() * 60 + stDt.getMinutes();
            var endValue = edDt.getHours() * 60 + edDt.getMinutes();
            var lastRoomValue = (_.last(rooms[key]) || 1440);
            var firstRoomValue = (_.first(rooms[key]) || 0);
            var newEndValue = (startValue + scheduler.config.event_duration);
            if ( (firstRoomValue <= startValue) && (lastRoomValue >= endValue) && !MeetingTypeStore.MeetingStore.isOffsiteSelected ) {
                scheduler.config.event_duration = scheduler.config.meetingMaximumDuration;
                scheduler.config.minimum_duration = scheduler.config.meetingMinimumDuration;
                if (lastRoomValue < (startValue + (diff || scheduler.config.event_duration) )) {
                    silent = 'neither_nor';
                } else {
                    silent = i18n.t('room_type');
                }
            } else {
                var lastOffsiteValue = (_.last(offsites[key]) || 1440);
                var firstOffsiteValue = (_.first(offsites[key]) || 0);
                if ( (firstOffsiteValue <= startValue) && (lastOffsiteValue >= endValue) ) {
                    scheduler.config.event_duration = scheduler.config.offsiteMaximumDuration;
                    scheduler.config.minimum_duration = scheduler.config.offsiteMinimumDuration;
                    if (lastOffsiteValue < (startValue + (diff || scheduler.config.event_duration) )) {
                        silent = 'neither_nor';
                    } else {
                        silent = i18n.t('offsite_type');
                    }
                } else {
                    if ( (firstOffsiteValue == lastRoomValue)) {
                        if (endValue > lastRoomValue && startValue < firstOffsiteValue) {
                            silent = 'neither_nor';
                        }
                    } else if (lastOffsiteValue == firstRoomValue) {
                        if (endValue > lastOffsiteValue && startValue < firstRoomValue) {
                            silent = 'neither_nor';
                        }
                    }
                }
            }
        }
        return silent;
    }

    function setupBlocking(options) {
        options = options || {};
        options = _.assign(options, {includeFullDay: true});
        scheduler.deleteMarkedTimespan();
        scheduler.updateView();
        if(eventData) {
            var startDate = scheduler.date.date_part(moment(eventData.start_date).utc()._d);
            var endDate = scheduler.date.date_part(moment(eventData.end_date).utc()._d);

            var state = scheduler.getState();
            var date = state.min_date;
            var stopDate = state.max_date;
            while(date < stopDate) {
                if(date < startDate || date > endDate) {
                    scheduler.blockTime(date, "fullday");
                }
                date = scheduler.date.add(date, 1, 'day');
            }
        }
        if (initialAvailability) {
            var availabilities;
                availabilities = Store.CalendarInitialAvailabilityStore.getInitialAvailability();
            var max = 0;
            var min = 1000000;
            _.forOwn(availabilities, function(availability, date) {
                var flattened = _.flatten(availability);
                min = _.min(flattened) < min ? _.min(flattened) : min;
                max = _.max(flattened) > max ? _.max(flattened) : max;
                var date = moment(date).utc()._d;
                scheduler.blockTime(date, scheduler.invertZones(availability));
                if (!calendarData) {
                    scheduler.addMarkedTimespan({
                        days: date,
                        zones: availability,
                        css: 'status-green',
                        html: i18n.t("available")
                    });
                }
            });
        }
        scheduler.config.first_hour = (min) / 60;
        scheduler.config.last_hour = (max) / 60;
        scheduler.updateView();
    }

    function onCalendarUpdates(data) {
        calendarData = data;
        updateCalendarView();
    }

    function updateCalendarView() {
        setupBlocking({includeFullDay:false});
        if(calendarData && calendarData.success) {
            var calendarInfo = calendarData.data.availability;
            _.forOwn(calendarInfo, function(availability, date){
                var flattened = _.flatten(availability);
                if(availability.length != 0)
                    scheduler.addMarkedTimespan({
                        days: moment(date).utc()._d,
                        zones: availability,
                        css: 'status-green',
                        html: i18n.t("available")
                    });
                scheduler.blockTime(moment(date).utc()._d, scheduler.invertZones(availability));
            });
            scheduler.updateView();
            var events = scheduler.getEvents();
            if(events.length > 0) {
                var event = events[0];
                var isInBlocked = scheduler.checkInMarkedTimespan(event, 'dhx_time_block');
                if(isInBlocked) {
                    showAlertAndRemoveEvent(event.id);
                }
            }
        }
    }

    function showAlertAndRemoveEvent(eventId) {
        scheduler.deleteEvent(eventId);
        notificationModal.notificationModal({
            timeout: true,
            body: i18n.t("slot_unavailable"),
            title: i18n.t('calendar_notify_title')
        });
    }

    function hideNonEventDays(eventStartDate, eventEndDate){
        scheduler.ignore_week = function(day){
           var isEventDay = false;

           if(day >= eventStartDate && day <= eventEndDate){
             isEventDay = true;
           }

           return (isEventDay == false);
        }
    }

    function onInitialAvailability(availability) {
        var rooms = (availability.data.room_initial_availabilities || {});
        var offsites = (availability.data.offsite_initial_availabilities || {});
        initialAvailability = {rooms: rooms, offsites: offsites};
        setupBlocking();
    }

    function init() {

        setupStoreListeners();
        Actions.initialAvailability();
        if(typeof briefing_uuid != "undefined")
            BriefingRequestActions.briefingDetails();
        else
            Actions.eventInfo();
    }


    return {
        init: init
    }

}());

module.exports = CalendarHandler;


}).call(this,require('_process'),typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {},require("buffer").Buffer,arguments[3],arguments[4],arguments[5],arguments[6],"/app/scripts/Book/Calendar/handler.js","/app/scripts/Book/Calendar")
},{"../Attendee/actions":2,"../BriefingRequest/actions":5,"../BriefingRequest/store":6,"../MeetingInMaking/actions":10,"../MeetingType/actions":14,"../MeetingType/store":16,"./actions":7,"./store":9,"_process":28,"buffer":24}],9:[function(require,module,exports){
(function (process,global,Buffer,__argument0,__argument1,__argument2,__argument3,__filename,__dirname){
var CalendarActions = require("./actions");
var Api = require('common_api');
var Actions = require('./actions');
var MeetingTypeStore = require('../MeetingType/store');

var CalendarEventStore = Reflux.createStore({

    init: function () {
        this.listenToMany(CalendarActions);
    },
    onEventInfo: function() {
        var promise = Api.fetch({
            url: Api.ENDPOINTS.events_info
        });
        promise.then(function(data){
            if(meetingInfo && meetingInfo.request) {
                data.meetingRequest = meetingInfo.request
            }
            this.trigger({success: true, data: data});
        }.bind(this));

        promise.catch(function(error){
            this.trigger({success:false, data: error.responseJSON});
        }.bind(this))
    }
});

var CalendarAvailabilityStore = Reflux.createStore({
    init: function() {
        this.listenTo(CalendarActions.updateCalendar, this.onUpdateCalendar);
        this.availabilities = {};
    },
    onUpdateCalendar: function(model) {
        var external_users = [];
        var roomUUID = _.result(model.room, 'uuid','');
        this.isOffsiteSelected = !!model.room.address;
        var users = _.pluck(model.internal,'uuid');
        if(typeof jiffle !== 'undefined'){
            if(model.external.length >= 1){
                _.forEach(model.external, function(external){
                    external_users.push({
                        title: external.title || "-",
                        uuid: external.uuid, 
                        first_name: external.first_name, 
                        last_name: external.last_name, 
                        email: external.email,
                        contact_no: external.contact_no || "-",
                        company_name: external.company_name
                    });
                });
            }
        }
        else {
            users = users.concat(_.pluck(model.external, 'uuid'));
        }
        if(users.length >= 0)  {
            var payload = {resources:{rooms:[roomUUID],users:users,external_users:external_users}}
            if(meetingInfo.request) {
                payload['meeting_uuid'] = meetingInfo.request.uuid;
            }

            if(typeof briefing_uuid != "undefined") {
                payload['briefing_uuid'] = briefing_uuid;
            }
            payload.book_meeting = true;
            if (CalendarInitialAvailabilityStore.isOffsiteEnabled) {
                payload.offsite_selected = MeetingTypeStore.MeetingStore.isOffsiteSelected ? "yes": "no";
            }
            var promise = Api.fetch({
                url: Api.ENDPOINTS.calendar_availability,
                data: payload
            });
            promise.then(function(data){
                this.availabilities = data;
                this.trigger(data);
            }.bind(this));

            promise.catch(function(error){
                console.log("Error", error)
                this.trigger(error.responseJSON);
            }.bind(this));
        } else {
            Actions.initialAvailability();
        }
    }
});


var CalendarInitialAvailabilityStore = Reflux.createStore({
    init: function() {
        this.listenTo(CalendarActions.initialAvailability, this.onInitialAvailability);
        this.initialAvailabilities = {};
        this.isOffsiteEnabled = false;
    },

    onInitialAvailability: function(isOffsiteEnabled) {

        var params = {};

        if(typeof briefing_uuid != "undefined") {
            params['briefing_uuid'] = briefing_uuid;
        }
        params['book_meeting'] = true;
        if (isOffsiteEnabled) {
            this.isOffsiteEnabled = true;
        }

        var promise = Api.fetch({
            url: Api.ENDPOINTS.availability_fetch,
            data : params
        });
        promise.then(function(data){
            this.initialAvailabilities = data;
            this.trigger(data);
        }.bind(this));
        promise.catch(function(error){

        }.bind(this));
    },
    getInitialAvailability: function() {
        var availabilityData = this.initialAvailabilities.data;
        if (availabilityData.room_offsite_availabilities) {
            this.isOffsiteEnabled = true;
            return availabilityData.room_offsite_availabilities;
        } else {
            this.isOffsiteEnabled = false;
            return this.initialAvailabilities.data.room_initial_availabilities;
        }
    }
});


module.exports = {
    CalendarEventStore: CalendarEventStore,
    CalendarAvailabilityStore: CalendarAvailabilityStore,
    CalendarInitialAvailabilityStore:CalendarInitialAvailabilityStore
};



}).call(this,require('_process'),typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {},require("buffer").Buffer,arguments[3],arguments[4],arguments[5],arguments[6],"/app/scripts/Book/Calendar/store.js","/app/scripts/Book/Calendar")
},{"../MeetingType/store":16,"./actions":7,"_process":28,"buffer":24,"common_api":"common_api"}],10:[function(require,module,exports){
(function (process,global,Buffer,__argument0,__argument1,__argument2,__argument3,__filename,__dirname){
// var Reflux = require('reflux');


var actions = Reflux.createActions([
    'createMeeting',
    'editMeeting',
    'rescheduleMeeting',
    'cancelMeeting',
    'updateAreYouAttending',
    'acceptMeeting',
    'declineMeeting',
    'getCustomForm'
]);



module.exports = actions;



}).call(this,require('_process'),typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {},require("buffer").Buffer,arguments[3],arguments[4],arguments[5],arguments[6],"/app/scripts/Book/MeetingInMaking/actions.js","/app/scripts/Book/MeetingInMaking")
},{"_process":28,"buffer":24}],11:[function(require,module,exports){
(function (process,global,Buffer,__argument0,__argument1,__argument2,__argument3,__filename,__dirname){
var MeetingInMakingActions = require("./actions");
var Api = require('common_api');

var CustomFormStore = Reflux.createStore({

  init: function() {
    this.listenToMany(MeetingInMakingActions);
    this.customForm = null;
  },

  onGetCustomForm: function(data) {
    var promise = Api.fetch({
        url: Api.ENDPOINTS.fetch_form,
        data: {"form_type": "meeting_request_form" }
      }).then(function(data) {
        if(this.customForm === null && data && data.custom_form_fields) {
          this.customForm = data;
          this.trigger(data);
        }
      }.bind(this)).catch(function(error) {
          console.log(error);
      });

  }
});

module.exports = CustomFormStore;



}).call(this,require('_process'),typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {},require("buffer").Buffer,arguments[3],arguments[4],arguments[5],arguments[6],"/app/scripts/Book/MeetingInMaking/form_store.js","/app/scripts/Book/MeetingInMaking")
},{"./actions":10,"_process":28,"buffer":24,"common_api":"common_api"}],12:[function(require,module,exports){
(function (process,global,Buffer,__argument0,__argument1,__argument2,__argument3,__filename,__dirname){
var Actions = require('./actions');
var Store = require('./store');
var CustomFormStore = require("./form_store");
var AttendeeActions = require('../Attendee/actions');
var FormRenderer = require('../../commons/form_renderer');

var MeetingMakingHandler = (function () {
    var meetingIdEl = $('.book-meeting .meeting-id');
    var meetingInMakingContainer = $(".section-meeting-making");
    var roomInfoContainer = $(".selected-room", meetingInMakingContainer);
    var timeInfoContainer = $(".selected-time", meetingInMakingContainer);
    var proceedPageContainer = $("#proceed_page");
    var mainPageContainer = $("#meeting-request-container");
    var proceedRoomContainer = $(".selected-room", proceedPageContainer);
    var proceedTimeContainer = $(".selected-time", proceedPageContainer);
    var submitButton = $("#submitButton");
    var proceedExternalContainer = $(".selected-external-attendee .selected-attendee-list", proceedPageContainer);
    var selectedExternalContainer = $(".selected-external-attendee .selected-attendee-list", meetingInMakingContainer);

    var proceedInternalContainer = $(".selected-internal-attendee .selected-attendee-list", proceedPageContainer);
    var selectedInternalContainer = $(".selected-internal-attendee .selected-attendee-list", meetingInMakingContainer);
    var dynamicFormContainer = $("#dynamic_form", proceedPageContainer);

    var proceedBtn = $("#proceed-btn");
    var goToMainBtn = $(".go-to-main", proceedPageContainer);

    var meetingInMakingContainer = $(".section-meeting-making");
    var attendingMeetingYes = $("input#attend-meeting-yes");
    var attendingMeetingNo = $("input#attend-meeting-no");
    var statusLine = $("a", 'li.blue-top-align');

    var loggedInUserLabel = $("#logged-in-user-label");
    var statusIndicator = $(".meeting-status");
    var statusButton = $(".approved-text");
    var formRenderer = null;
    var acceptMeeting = $(".accept-meeting");
    var declineMeeting = $(".decline-meeting");
    var notifyModalEl =$(".notification-modal");
    var isRequestorChangedByUserAction = false;
    var totalAttendeeCount = 0;
    var currRoomCapacity = 0;
    var roomLabeLocaleKey = "room";

    var eventHandlers = {
        onRoomChosen: onRoomChosen,
        onAttendeeSelected: onAttendeeSelected,
        onEventCreated: onEventCreated,
        onMeetingCancelled: onMeetingCancelled,
        onMeetingCancelFailed: onMeetingCancelFailed,
        onEventSaved: onEventSaved,
        onEventSaveFailed: onEventSaveFailed,
        onEventRescheduled: onEventRescheduled,
        onAcceptDeclineMeeting: onAcceptDeclineMeeting
    }
    var cancelBtn = $('#cancel-btn');
    var cancelMeetingBtn = $(".cancel-meeting");


    function init() {

        if (typeof isEBCEvent != 'undefined' && isEBCEvent == true) {
            roomLabeLocaleKey = "briefing_center";
        }
        Store.listen(function(data){
            var action = data.action;
            var payload = data.payload || {};
            var func = eventHandlers[action];
            if(func) {
                func(payload);
            }
        });
        Actions.getCustomForm();
        CustomFormStore.listen(updateCustomFormStore);

        checkRequestorFromMapping();
        populateRequestorOptions();
        proceedBtn.on('click', showProceedPage);
        cancelMeetingBtn.on('click', discardMeeting);
        proceedPageContainer.on('click', '.go-to-main', showMainPage);
        proceedPageContainer.on('click', '.go-to-main-external', showExternalAttendeesInMainPage);
        proceedPageContainer.on('click', '.go-to-main-internal', showInternalAttendeesInMainPage);
        proceedPageContainer.on('click','.cancel-meeting-request', cancelMeetingRequest);
        proceedPageContainer.on('click', '.attendee-empty-state.internal', showInternalAttendeesInMainPage);
        proceedPageContainer.on('click', '.attendee-empty-state.external', showExternalAttendeesInMainPage);
        $('.selected-internal-attendee',proceedPageContainer).on('click', '.remove', unselectInternalAttendee);
        $('.selected-external-attendee',proceedPageContainer).on('click', '.remove', unselectExternalAttendee);

        proceedPageContainer.on('click', "#submitButton", function(e){
            e.preventDefault();
            var form = $("#customer_form");
            form.validate({
                ignore: [],
            });

            var meetingSummaryForm = $("form.meeting-summary");
            meetingSummaryForm.validate();
            var requestor = $("#requestor-select").val();
            var isMeetingValid = Store.isValidMeeting();
            if(isMeetingValid.error) {
                notifyModalEl.notificationModal({
                    class: "red",
                    timeout: true,
                    body: isMeetingValid.message,
                    title: isMeetingValid.title || i18n.t("meeting_validation_notify_title"),
                });
            }
            var formData = formRenderer.getValues();

            if(isMeetingValid.error === false && form.valid() && meetingSummaryForm.valid()){
                $("#cover").fadeIn();
                if(meetingInfo.request && meetingInfo.request.mode === "edit") {
                    Actions.rescheduleMeeting(formData, requestor);
                } else {
                    Actions.createMeeting(formData, requestor);
                }
            }
        });
        if(meetingInfo && meetingInfo.request.showCancel) {
            $(".cancel-meeting-item").removeClass("hide");
        }
        loggedInUserLabel.html("");
        cancelBtn.on('click', discardMeeting);
        acceptMeeting.on('click', 'a', onAcceptMeeting);
        declineMeeting.on('click', 'a', onDeclineMeeting);
        shouldOpenEditMeeting();
    };

    function disableInternalAttendeeRemoval(validInternalAttendees) {
        var hasInValidInternalAttendees = validInternalAttendees.length <= 1;
        if (hasInValidInternalAttendees) {
            var validAttendee = validInternalAttendees[0] || {};
            $('#internal-attendees-tab .selected-attendee .unselect-attendee[data-uuid="'+validAttendee.uuid+'"]', mainPageContainer).attr('ask_confirm', '');
        } else {
            $('#internal-attendees-tab .selected-attendee .unselect-attendee', mainPageContainer).removeAttr('ask_confirm');
        }
        return hasInValidInternalAttendees;

    }

    function checkRequestorFromMapping() {
        if (meetingInfo.request && meetingInfo.request.mode === "edit") {
            var meetingRequestorUuid = meetingInfo.request.requestor.uuid,
                isRequestorPresent = false;

            for (var i = meetingInfo.requestors.length - 1; (!isRequestorPresent && i >= 0); i-- ) {
                isRequestorPresent = (meetingInfo.requestors[i][1] === meetingRequestorUuid);
            }
            if (isRequestorPresent === false) {
                meetingInfo.requestors.push([ meetingInfo.request.requestor.first_name + " " + meetingInfo.request.requestor.last_name, meetingRequestorUuid ])
            }
        }
    }

    function showInternalAttendeesInMainPage(e) {
        showMainPage(e);
        AttendeeActions.showAttendeesList('internal');
    }

    function showExternalAttendeesInMainPage(e) {
        showMainPage(e);
        AttendeeActions.showAttendeesList('external');
    }

    function onAcceptMeeting(e) {
      e.preventDefault();
      e.stopPropagation();
      var currentUser = envDetails.currentUser.uuid;
      Actions.acceptMeeting(meetingInfo.request.uuid, currentUser);
    };

    function onDeclineMeeting(e) {
      e.preventDefault();
      e.stopPropagation();
      var currentUser = envDetails.currentUser.uuid;
      Actions.declineMeeting(meetingInfo.request.uuid, currentUser);
    };

    function cancelMeetingRequest(e) {
        e.preventDefault();
        e.stopPropagation();
        notifyModalEl.notificationModal({
            type: 'confirmation',
            title: i18n.t("cancel_meeting_title"),
            body: i18n.t("cancel_meeting_confirmation"),
            done: function(){
                var uuid = meetingInfo.request.uuid;
                Actions.cancelMeeting(uuid);
            }
        });
    };

    function discardMeeting(e) {
        e.preventDefault();
        e.stopPropagation();
        notifyModalEl.notificationModal({
            type: 'confirmation',
            title: i18n.t("discard_meeting_title"),
            body: i18n.t("discard_meeting_confirmation"),
            done: function(){
                var newPage = envDetails.urlPrefix + "/meeting_list";
                window.location.href = newPage;
            }
        });
    };

    function updateCustomFormStore(data) {

        formRenderer = $(dynamicFormContainer).formRenderer({fieldCollection: data.custom_form_fields});
        formRenderer.init();
        if(meetingInfo.request) {
            meetingInfo.request.custom_fields = meetingInfo.request.custom_fields || {};
            formRenderer.setValues(meetingInfo.request)
        }
    };

    function _updateAcceptDecline(actions) {
      acceptMeeting.addClass("hide");
      declineMeeting.addClass("hide");
      if(actions.length === 2) {
        acceptMeeting.removeClass("hide");
        declineMeeting.removeClass("hide");
      } else {
        if(actions.length === 1 && actions[0] === i18n.t('decline')) {
          declineMeeting.removeClass("hide");
        }
      }
    };

    function shouldOpenEditMeeting() {
        if(meetingInfo && meetingInfo.request && meetingInfo.request.mode === "edit") {
            mainPageContainer.addClass('hide');
            proceedPageContainer.removeClass('hide');
            _updateAcceptDecline(meetingInfo.request.actions);
            var form = $("#customer_form");
            $(".cancel-meeting-request").removeClass("hide");
            meetingIdEl.removeAttr("data-i18n");
            meetingIdEl.text(i18n.t('meeting_id') + meetingInfo.request.id);
            statusButton.text(meetingInfo.request.status);
            statusIndicator.addClass(meetingInfo.request.status);
            window.scrollTo(0,0);
            var internalAttendees = meetingInfo.request.users.internal;
            var currentUserUuid = envDetails.currentUser.uuid;
            var isLoggedInUserInInternalList = _.find(internalAttendees, function(attendee){
                return attendee.uuid === currentUserUuid && attendee.invite_status !== 'declined';
            });

            if(isLoggedInUserInInternalList) {
                attendingMeetingYes.prop("checked",true);
                var name = envDetails.currentUser.first_name + " " + envDetails.currentUser.last_name+", ";
                loggedInUserLabel.html(name);
                Actions.updateAreYouAttending(true);
                statusLine.html(i18n.t('you_are_attending'));
            } else {
                attendingMeetingNo.prop("checked",true);
                Actions.updateAreYouAttending(false);
                statusLine.html(i18n.t('you_are_not_attending'));
            }
            var select = $("#requestor-select");
            var requestor = meetingInfo.request.requestor;
            if (requestor && requestor.uuid) {
              select.val(requestor.uuid);
            }
            submitButton.attr("data-i18n", "UPDATE");
        }
    };

    function editMeeting(meetingData) {
    };

    function showProceedPage(e) {
        e && e.preventDefault();
        var valid = Store.isValidMeeting();
        if (valid.error === false) {
            mainPageContainer.addClass('hide');
            proceedPageContainer.removeClass('hide');
            window.scrollTo(0,0);
        } else {
            notifyModalEl.notificationModal({
                class: "red",
                timeout: true,
                body: valid.message,
                title: valid.title || i18n.t("meeting_validation_notify_title"),
            });
            return;
        }
        if (isRequestorChangedByUserAction) {
            return;
        }
        var currentUserUuid = envDetails.currentUser.uuid;
        var isCurrentUserEA = envDetails.isExecutiveAdmin();


        var select = $("#requestor-select");
        var selectedVal = select.val();
        if (meetingInfo.request.mode === 'new') {
            // if new meeting

            if (isCurrentUserEA) {
              var currentManagedUser = envDetails.currentManagedUser;

              if (currentManagedUser == 'All' || currentManagedUser == currentUserUuid) {
                _.first(select.find('option')).selected = true;
              } else {
                select.find('option').each(function(index, option) {
                  if(currentManagedUser == option.value){
                    option.selected = true;
                  }
                });
              }

            } else {
                select.find('option').each(function(index, option) {
                    if (currentUserUuid === option.value) {
                        option.selected = true;
                    }
                });
            }
            //For SFDC Book Meeting
            if(typeof jiffle !== 'undefined'){
                var accountName = require('../SfdcAccount/store').selectedAccount.name;
                meetingInfo.request.meeting_with = accountName;
                formRenderer.setValue("meeting_with", accountName);
            }

        } else {
            if (isCurrentUserEA) {

            }
        }
    };

    function populateRequestorOptions() {
        var requestorSelect = $("#requestor-select");
        var pleaseSelect = $("<option/>").val("").html(i18n.t('please_select'));
        var currentUserUuid = envDetails.currentUser.uuid;
        // populate new options
        var options = meetingInfo.requestors.map(function(attendee) {
            var cls = '';
            if (currentUserUuid === attendee[1]) {
                cls = 'hide';
            }
            return $("<option class='"+ cls +"'>").val(attendee[1]).html(attendee[0]);
        });
        options.unshift(pleaseSelect);
        requestorSelect.on('change', function() {
            isRequestorChangedByUserAction = true;
            requestorSelect.off('change');
        });
        requestorSelect.append(options);
    };

    function showMainPage(e) {
        e.preventDefault();
        e.stopPropagation();
        mainPageContainer.removeClass('hide');
        proceedPageContainer.addClass('hide');
        window.scrollTo(0,0);
        scheduler.update_view();
    };

    function unselectInternalAttendee(e) {
        e.preventDefault();
        e.stopPropagation();
        if (this.hasAttribute("ask_confirm")) {
            notifyModalEl.notificationModal({
                title: i18n.t('meeting_notify_failure_title'),
                body: i18n.t('select_min_internal_attendee_to_continue', { company_name: envDetails.companyName }),
                class: 'red',
                dismiss: function() {
                }
            })
            return;
        }
        var uuid = $(this).data('uuid');
        if (uuid === envDetails.currentUser.uuid) {
            $("a", 'li.blue-top-align').html(i18n.t("you_are_not_attending"))
            attendingMeetingNo.prop('checked', true);
        }
        AttendeeActions.unselectInternalAttendee(uuid);
        showHideMeetingMaking();
    };

    function unselectExternalAttendee(e) {
        e.preventDefault();
        var uuid = $(this).data('uuid');
        AttendeeActions.unselectExternalAttendee(uuid);
        showHideMeetingMaking();
    };

    function onRoomChosen(payload) {
        var template = HandlebarsTemplates['book/selected_room'];
        var proceedTemplate = HandlebarsTemplates['book/proceed_room'];
        var data;
        if(payload && payload.type && payload.room) {
            if(payload.offsite) {

                data = {name : payload.type.display_name, offsite: true, address: payload.room.address, name: payload.room.name, capacity: ''};
            } else {
                data = {name : payload.type.display_name, offsite: false, display_name: payload.type.display_name, room_name: payload.room.name, capacity: payload.room.capacity};
            }
            var html = template(data);
            data.showGotoMainOptionFromDetails = true;
            currRoomCapacity = data.capacity;
            var proceedHtml = proceedTemplate(data);
        } else {
            var html = template({});
            var proceedHtml = proceedTemplate({});
        }
        proceedRoomContainer.html(proceedHtml);
        roomInfoContainer.html(html);
        updateRoomLabel();
        if(payload.room) {
            $("#room-label").html(payload.offsite ? data.name : data.room_name);
        } else {
            updateTopRoomLabel();
        }
        showHideMeetingMaking();
    };

    function updateTopRoomLabel() {
        if (!!window.isEBCEvent) {
          roomLabeLocaleKey = i18n.t("briefing_center");
        } else {
          var keys = [];
          if (scheduler.config.can_book_room) {
              keys.push(i18n.t('room'));
          }
          if (scheduler.config.can_book_offsite) {
              keys.push(i18n.t('offsite'));
          }
          roomLabeLocaleKey = keys.join(', ');
        }
        $("#room-label").html(roomLabeLocaleKey);
    }

    function showHideMeetingMaking() {
        if(Store.canShowMeetingInMaking()) {
            meetingInMakingContainer.removeClass('hide');
        } else {
            meetingInMakingContainer.addClass('hide');
        }
    };

    function updateRoomLabel() {
        var roomFullHolder = $("#roomFullHolder"),
            occupiedRoomHolder = $("#occupiedRoomHolder"),
            availableRoomCount = currRoomCapacity - totalAttendeeCount;

        if (availableRoomCount <= 0) {
            roomFullHolder.removeClass('hide');
            occupiedRoomHolder.addClass('hide');
        } else {
            roomFullHolder.addClass('hide');
            occupiedRoomHolder.removeClass('hide').find('.occupiedCount').text(availableRoomCount);
        }
    }

    function onAttendeeSelected(payload) {
        var template = HandlebarsTemplates['book/selected_attendee'];
        var internalCount = payload.internalAttendee.length,
            externalCount = payload.externalAttendee.length;
        var askConfirm = false;
        totalAttendeeCount = internalCount+externalCount;
        updateRoomLabel();
        $(".selectedInternalAttendeeCount").text( ( (internalCount < 10 && internalCount != 0) ? "0": "") + internalCount);
        $(".selectedInternalAttendeeCount + span").html( i18n.t( (internalCount == 1) ? 'internal_participant' : 'internal_participants') );
        $(".selectedExternalAttendeeCount").text( ( (externalCount < 10 && externalCount != 0) ? "0": "") + externalCount);
        $(".selectedExternalAttendeeCount + span").html( i18n.t( (externalCount == 1) ? 'external_participant': 'external_participants') );
        askConfirm = disableInternalAttendeeRemoval(payload.validInternalAttendees);

        var internalHtml = template({users:payload.internalAttendee, type: "internal"});
        selectedInternalContainer.html(internalHtml);
        var externalHtml = template({users:payload.externalAttendee, type: "external"});
        selectedExternalContainer.html(externalHtml);
        internalHtml = template({users:payload.internalAttendee, askConfirm: askConfirm, remove: true, type: "internal"});
        proceedInternalContainer.html(internalHtml);
        externalHtml = template({users:payload.externalAttendee, askConfirm: false, remove:true, type: "external"});
        proceedExternalContainer.html(externalHtml);



        $("a.add-participant", proceedExternalContainer).html(i18n.t("add_external_participants"));
        if(payload.internalAttendee.length > 0  || payload.externalAttendee.length > 0) {
            $("#attendee-label").removeClass('hide');
        } else {
            $("#attendee-label").addClass('hide');
        }
        if(payload.internalAttendee.length > 0 ) {
            $(".attendee-empty-state", proceedInternalContainer).addClass("hide");
            $(".go-to-main, .go-to-main-internal", ".selected-internal-attendee").removeClass("hide");
        } else {

            $(".attendee-empty-state", proceedInternalContainer).removeClass("hide");
            $(".go-to-main, .go-to-main-internal", ".selected-internal-attendee").addClass("hide");
        }

        if(payload.externalAttendee.length > 0 ) {
            $(".attendee-empty-state", proceedExternalContainer).addClass("hide");
            $(".go-to-main, .go-to-main-external", ".selected-external-attendee").removeClass("hide");
        } else {
            $(".attendee-empty-state", proceedExternalContainer).removeClass("hide");
            $(".go-to-main, .go-to-main-external", ".selected-external-attendee").addClass("hide");

        }
        showHideMeetingMaking();
    };

    function onMeetingCancelled(payload) {
        var newPage = envDetails.urlPrefix + "/meeting_list";
        if(typeof jiffle !== 'undefined'){
            var search = window.location.search;
            var mode = new RegExp('[\?&]mode=([^&#]*)').exec(search)
            var meeting = new RegExp('[\?&]meeting=([^&#]*)').exec(search);
            if(meeting){
                search = search.replace(meeting[0], "");
            }
            if(mode){
                search = search.replace(mode[0], "");
            }

            newPage = "/apex/JNMeetings" + search;
        }
        window.location.href = newPage;
    };

    function onEventCreated(payload) {

        var template = HandlebarsTemplates['book/selected_time'];
        var proceedTemplate = HandlebarsTemplates['book/proceed_time'];

        if(payload.event) {

            var start_time = moment(payload.event.start_date).format('hh:mm a');
            var end_time = moment(payload.event.end_date).format('hh:mm a');
            var event_date = payload.event.start_date.toMediumDate();

            var html = template({start_time:start_time, end_time:end_time, event_date:event_date, display: true});
            timeInfoContainer.html(html);

            var showRescheduleTimeOption = mode == 'edit' ? true : false;
            var showChangeTimeOption = mode == 'new' ? true : false;

            html = proceedTemplate({start_time:start_time, end_time:end_time, event_date:event_date, uuid: payload.event.uuid, showRescheduleTimeOption: showRescheduleTimeOption, showChangeTimeOption: showChangeTimeOption, showGotoMainOptionFromDetails: true});
            proceedTimeContainer.html(html);

        }else{
            timeInfoContainer.html( template({display: false}));
            proceedTimeContainer.html( proceedTemplate());
        }
        showHideMeetingMaking();
    };

    function onEventSaved(payload) {
        var currentUserFirstName = envDetails.currentUser.first_name
        notifyModalEl.notificationModal({
            title: i18n.t('meeting_notify_success_title', { user_first_name: currentUserFirstName }),
            body: i18n.t("meeting_creation_success"),
            dismiss: function() {
                if(typeof briefing_uuid != "undefined") {
                    var baseUrl = document.getElementsByTagName('base')[0].href;
                    location.href = baseUrl +  '/briefing/list_briefings#/list_agenda/' + briefing_uuid;
                }
                else if(typeof jiffle !== 'undefined'){
                    location.href = "/apex/JNMeetings" + window.location.search;
                }
                else{
                    localStorage.setItem("eventId", payload.data.meeting_id);
                    location.href = envDetails.urlPrefix +  '/meeting_list';
                }
            }
        });
    };

    function onEventRescheduled(payload) {

        notifyModalEl.notificationModal({
            title: i18n.t('meeting_notify_success_title', {user_first_name: envDetails.currentUser.first_name}),
            body: i18n.t("meeting_updation_success"),
            dismiss: function() {
                localStorage.setItem("eventId", payload.data.meeting_id);
                if(typeof jiffle !== 'undefined'){
                    var search = window.location.search;
                    var mode = new RegExp('[\?&]mode=([^&#]*)').exec(search)
                    var meeting = new RegExp('[\?&]meeting=([^&#]*)').exec(search);
                    if(meeting){
                        search = search.replace(meeting[0], "");
                    }
                    if(mode){
                        search = search.replace(mode[0], "");
                    }

                    location.href = "/apex/JNMeetings" + search;
                }
                else {
                    location.href = envDetails.urlPrefix +  '/meeting_list'; 
                }
            }
        });
    };

    function onAcceptDeclineMeeting(payload) {
      var actions = payload.data.actions;
      _updateAcceptDecline(actions);
      var accepted = false;
      if(actions.length === 1 && actions[0] === i18n.t('decline'))
        accepted = true;
      var message = (accepted === true) ? "accepted_msg" : "declined_msg";
      notifyModalEl.notificationModal({
        body: i18n.t(message),
        title: i18n.t("meeting_status_notify_title"),
      });
      setTimeout(function(){
        window.location.href = envDetails['urlPrefix'] + "/meeting_list";
      }, 2 * 1000);
    };

    function onEventSaveFailed(payload) {
        var errors = [];
        _.forEach(payload.errors, function(error) {
            errors.push(error);
        });
        notifyModalEl.notificationModal({
            timeout: true,
            class: 'red',
            body: errors.join(', '),
            title: i18n.t('meeting_notify_failure_title'),
        });
    };

    function onMeetingCancelFailed(payload) {
        var errors = [];
        _.forEach(payload.errors, function(error) {
            errors.push(error);
        });
        notifyModalEl.notificationModal({
            class: 'red',
            body: errors.join(', '),
            title: i18n.t('cancel_meeting')
        });
    };

    return {
        init: init
    };
}());

module.exports = MeetingMakingHandler;



}).call(this,require('_process'),typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {},require("buffer").Buffer,arguments[3],arguments[4],arguments[5],arguments[6],"/app/scripts/Book/MeetingInMaking/handler.js","/app/scripts/Book/MeetingInMaking")
},{"../../commons/form_renderer":22,"../Attendee/actions":2,"../SfdcAccount/store":20,"./actions":10,"./form_store":11,"./store":13,"_process":28,"buffer":24}],13:[function(require,module,exports){
(function (process,global,Buffer,__argument0,__argument1,__argument2,__argument3,__filename,__dirname){
  var Actions = require("./actions");
var Api = require('common_api');
var MeetingTypeStore = require('../MeetingType/store');
var AttendeeStore = require('../Attendee/store').AttendeeStore;
var AddEditAttendeeStore = require('../Attendee/store').AddEditAttendeeStore;
var CalendarActions = require('../Calendar/actions');

var MeetingInMakingStore = Reflux.createStore({

    init: function() {
        this.model = {room:{uuid:''},external:[],internal:[], event: null, attendingMeetingStatus:null};
        this.listenTo(MeetingTypeStore.MeetingStore, this.onMeetingTypeChanged);
        this.listenTo(AttendeeStore, this.attendeeStoreSelection);
        this.listenTo(AddEditAttendeeStore, this.attendeeStoreSelection)
        this.listenTo(CalendarActions.eventCreated, this.onEventCreated);
        this.listenToMany(Actions);
    },

    onMeetingTypeChanged: function(data) {
      if(data.payload && (data.action === "onRoomChosen")){
        this.model['meetingType'] = data.payload.type;
        this.model['room'] = data.payload.room || {};
        scheduler.callEvent('onDragEnd');
        CalendarActions.updateCalendar(this.model);
        this.trigger(data);
      }
    },
    onCancelMeeting: function(uuid) {
      var url = Api.ENDPOINTS.cancel_meeting;
      url = url.replace('{meeting_uuid}',uuid);
      var promise = Api.fetch({
        url: url,
        global: true,
        type: 'PUT'
      });
      promise.then(function(data){
        this.trigger({action:'onMeetingCancelled', payload:data});
      }.bind(this));
      promise.catch(function(data){
        var response = data.responseJSON;
        if(typeof jiffle !== 'undefined'){
            response = data;
        }
        this.trigger({action:'onMeetingCancelFailed',payload: response});
      }.bind(this));
    },
    onUpdateAreYouAttending: function(value) {
      this.model.attendingMeetingStatus = value;
      this.trigger({action:'onYouAreAttending',payload:value});
    },
    attendeeStoreSelection: function(payload) {
        var type = payload.type;
        var user = payload.user;

        var uuid, count = 0;
        var canTrigger = false;
        if(type === 'internalAttendeeSelected') {
          canTrigger = true;
              if (user) {
                uuid = user.uuid;
                var userExists = _.find(this.model['internal'], function(u) {
                  return u.uuid === uuid;
                });
                if (!userExists) {
                  this.model['internal'].push(user);
                }
                this.model['internal'] = _.uniq(this.model['internal'], function(attendee) {
                    return attendee.uuid;
                });
              }
        }
        else if(type === 'externalAttendeeSelected') {
          canTrigger = true;
            if (user) {
              uuid = user.uuid;
              var userExists = _.find(this.model['external'], function(u) {
                return u.uuid === uuid;
              });
              this.model['external'].push(user);
              this.model['external'] = _.uniq(this.model['external'], function(attendee) {
                  return attendee.uuid;
              });
            }
        }
        else if(type === 'internalAttendeeUnselected') {
          canTrigger = true;
            uuid = user && user.uuid;
            var internal = this.model['internal'];
            internal = _.remove(internal, function(u) {
                return u.uuid === uuid;
            });
        }
        else if(type === 'externalAttendeeUnselected') {
          canTrigger = true;
            uuid = user && user.uuid;
            var external = this.model['external'];
            external = _.remove(external, function(u) {
                return u.uuid === uuid;
            });
        }
        else if(type === 'allExternalAttendeeUnselected') {
          canTrigger = true;
            var external = this.model['external'];
            _.forEach(user, function(oneUser){
              _.remove(external, function(u) {
                return u.uuid === oneUser.uuid;
              });
            });
        }
        else if (type === 'editAttendees') {
          canTrigger = true;
            this.model['internal'] = payload.users.internal.slice();
            this.model['external'] = payload.users.external.slice();
            if (payload.hasCurrUser) {
              this.model.attendingMeetingStatus = "yes";
            }
        }

        count = this.getAttendeeCount();
        if (canTrigger) {
          CalendarActions.updateCalendar(this.model);
          MeetingTypeStore.MeetingStore.showAvailableRooms(count, uuid);
          this.trigger({action: 'onAttendeeSelected', payload:{internalAttendee: this.model['internal'], externalAttendee: this.model['external'], validInternalAttendees: this.getNonDeclinedAttendees('internal') }});
        }
    },
    onEventCreated: function(event) {
        this.model['event'] = event;
        this.trigger({action: 'onEventCreated', payload:{event: this.model.event}});
    },

    isAttendeeRequired: function(type) {
       return MeetingTypeStore.MeetingStore.meetingTypes[0].settings[type] === "t";
    },

    isAccountSelected: function(){
      var account = require("../SfdcAccount/store").selectedAccount.id;
      return (account) ? true : false;
    },

    isValidMeeting: function() {
        var validationMsg;
        if(this.model.attendingMeetingStatus === null) {
            validationMsg = i18n.t("select_if_attending_to_continue");
            return {
              error: true,
              message: validationMsg,
              title: i18n.t("select_if_attending_to_continue_title")
            };
        }
        if(this.model.event === null) {
            validationMsg = i18n.t("select_timeslot_to_continue");
            return {
              error: true,
              message: validationMsg,
              title: i18n.t("select_timeslot_to_continue_title")
            };
        }
        if ( (this.model.room.uuid === '' || this.model.room.uuid === undefined) ^ (this.model.room.address !== undefined)) {
            validationMsg = i18n.t("select_room_to_continue");
            return {
              error: true,
              message: validationMsg,
              title: i18n.t("select_room_to_continue_title")
            };
        }


        if(this.isAttendeeRequired('internal_attendee_mandatory') && this.model.internal.length === 0) {
            validationMsg = i18n.t("select_min_internal_attendee_to_continue", { company_name: envDetails.companyName });
            return { error: true, message: validationMsg, title: i18n.t('meeting_notify_failure_title') };
        }

        if(this.isAttendeeRequired('external_attendee_mandatory') && this.model.external.length === 0) {
            validationMsg = i18n.t("select_min_external_attendee_to_continue");
            return { error: true, message: validationMsg, title: i18n.t('meeting_notify_failure_title') };
        }

        if (this.getNonDeclinedAttendees('internal').length < 1) {
          validationMsg = i18n.t("select_min_internal_attendee_to_continue", { company_name: envDetails.companyName });
          return {
            error: true,
            title: i18n.t('meeting_notify_failure_title'),
            message: validationMsg
          }
        }
        return {error: false};
    },
    getNonDeclinedAttendees: function(type) {
      return _.filter(this.model[type], function(user) {
        return (user && user.invite_status !== "declined");
      }) || [];
    },
    getAttendeeCount: function() {
        var internalCount = this.getNonDeclinedAttendees('internal').length;
        var externalCount = this.getNonDeclinedAttendees('external').length;
        return internalCount+externalCount;
    },
    canShowMeetingInMaking: function() {
      var model = this.model;
      return (model.event !== null || ((typeof model.room.uuid !== 'undefined') ^ (typeof model.room.address !== 'undefined')) || model.internal.length !== 0 || model.external.length !== 0) ;
    },
    onCreateMeeting: function(formData, requestor) {
      var users = this.model.internal.map(function(user){return user.uuid});
      users = users.concat(this.model.external.map(function(user){return user.uuid}));
      var format = "YYYY-MM-DD HH:mm A";
      var meetingWith = formData.meeting_with;
      delete formData["meeting_with"]
      var meetingRequest = {
        meeting_type: this.model.meetingType.uuid,
        meeting_with: meetingWith,
        start_time: moment(this.model.event.start_date).format(format),
        end_time: moment(this.model.event.end_date).format(format),
        users: users,
        custom_fields: formData,
        requestor: requestor
      }

      if(this.model.room.address !== undefined) {
        meetingRequest['offsite_location_name'] = this.model.room.name;
        meetingRequest['offsite_location_address'] = this.model.room.address;
      } else {
        meetingRequest['room_uuid'] = this.model.room.uuid;
      }

      if(typeof jiffle !== 'undefined'){
        var AccountStore = require("../SfdcAccount/store");
        meetingRequest['account_id'] = AccountStore.selectedAccount.id;
        meetingRequest['opportunity_id'] = AccountStore.selectedOpportunity.id;
      }

      var payload = {meeting_request: meetingRequest};

      if(typeof briefing_uuid != "undefined") {
          payload['briefing_uuid'] = briefing_uuid;
      }

      var promise = Api.update({
        url: Api.ENDPOINTS.meeting_create,
        global: true,
        data: payload
      });

      promise.then(function(data){
        this.trigger({action:'onEventSaved', payload:data});
      }.bind(this));

      promise.catch(function(data){
        var response = data.responseJSON;
        if(typeof jiffle !== 'undefined'){
            response = data;
        }
        this.trigger({action:'onEventSaveFailed',payload: response});
      }.bind(this));
    },
    filterDeclined: function(users) {
      return _.partition(users, function(user){
        if(user.invite_status && user.invite_status === "declined")
          return false;
        return true;
      })
    },
    onRescheduleMeeting: function(formData, requestor) {
      var internalUsers = this.filterDeclined(this.model.internal);
      var externalUsers = this.filterDeclined(this.model.external);
      var users = _.pluck(internalUsers[0], 'uuid');
      users = users.concat(_.pluck(externalUsers[0], 'uuid'));
      var declinedUsers = _.pluck(internalUsers[1], 'uuid');
      declinedUsers = declinedUsers.concat(_.pluck(externalUsers[1], 'uuid'));
      var format = "YYYY-MM-DD HH:mm A";
      var meetingWith = formData.meeting_with;
      delete formData["meeting_with"]

      var meetingRequest = {
        meeting_type: this.model.meetingType.uuid,
        meeting_with: meetingWith,
        start_time: moment(this.model.event.start_date).format(format),
        end_time: moment(this.model.event.end_date).format(format),
        users: users,
        declined_attendees: declinedUsers,
        custom_fields: formData,
        requestor: requestor,
        meeting_uuid: meetingInfo.request.uuid
      }

      if(this.model.room.address !== undefined) {
        meetingRequest['offsite_location_name'] = this.model.room.name;
        meetingRequest['offsite_location_address'] = this.model.room.address;
      } else {
        meetingRequest['room_uuid'] = this.model.room.uuid;
      }

      var payload = {meeting_request: meetingRequest, meeting_uuid: meetingInfo.request.uuid};

      if(typeof briefing_uuid != "undefined") {
          payload['briefing_uuid'] = briefing_uuid;
      }

      var promise = Api.update({
          url: Api.ENDPOINTS.reschedule_meeting,
          global: true,
          data: payload
      });
      promise.then(function(data){
        this.trigger({action:'onEventRescheduled', payload:data});
      }.bind(this));
      promise.catch(function(error){
        this.trigger({action:'onEventSaveFailed',payload: error});
      }.bind(this));
    },
    onAcceptMeeting: function(meetingUuid, userUuid) {
      this._acceptDeclineMeeting(meetingUuid, userUuid, 'accept');
    },
    onDeclineMeeting: function(meetingUuid, userUuid) {
      this._acceptDeclineMeeting(meetingUuid, userUuid, 'decline');
    },
    _acceptDeclineMeeting: function(meetingUuid, userUuid, type) {
      var currentUserUUID = envDetails.currentUser.uuid;
      if(type == 'accept')
        var url = Api.ENDPOINTS.accept_meeting.replace('{uuid}',meetingUuid);
      else
        var url = Api.ENDPOINTS.decline_meeting.replace('{uuid}',meetingUuid);

      var promise = Api.update({
        url: url,
        data: {user_uuid: userUuid},
      });

      promise.then(function(data){
          this.trigger({action:'onAcceptDeclineMeeting',payload:{data:data.data}});
      }.bind(this));

      promise.catch(function(error){
        console.log(error.responseText);
      }.bind(this));
    },
    getInternalAttendees: function() {
      return this.model.internal;
    }
});

module.exports = MeetingInMakingStore;



}).call(this,require('_process'),typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {},require("buffer").Buffer,arguments[3],arguments[4],arguments[5],arguments[6],"/app/scripts/Book/MeetingInMaking/store.js","/app/scripts/Book/MeetingInMaking")
},{"../Attendee/store":4,"../Calendar/actions":7,"../MeetingType/store":16,"../SfdcAccount/store":20,"./actions":10,"_process":28,"buffer":24,"common_api":"common_api"}],14:[function(require,module,exports){
(function (process,global,Buffer,__argument0,__argument1,__argument2,__argument3,__filename,__dirname){
var MeetingTypeActions = Reflux.createActions([
    'getAllMeetingTypes',
    'meetingTypeChosen',
    'roomChosen',
    'offsiteChosen',
    'eventCreated',
    'editRoom',
    'searchRoom',
    'attendeeCountChanged',
    'updateFilter',
    'applyFilter',
    'resetFilter'
]);

module.exports = MeetingTypeActions;



}).call(this,require('_process'),typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {},require("buffer").Buffer,arguments[3],arguments[4],arguments[5],arguments[6],"/app/scripts/Book/MeetingType/actions.js","/app/scripts/Book/MeetingType")
},{"_process":28,"buffer":24}],15:[function(require,module,exports){
(function (process,global,Buffer,__argument0,__argument1,__argument2,__argument3,__filename,__dirname){
var MeetingActions = require('./actions');
var Store = require('./store');
var CalendarActions = require('../Calendar/actions');
var AttendeeActions = require('../Attendee/actions');

var MeetingTypeHandler = (function () {
    var meetingContainer = $(".meeting-list");
    var roomContainer = $(".room-list");
    var roomSearchBox = $(".room-search-box");
    var roomFilterSearch = $("#room-filter-search");
    var meetingTypeWidget = $(".meeting-type");
    var meetingStore = Store.MeetingStore;
    var offsiteLocationContainer = $(".offsite-location");
    var selectRoomBtn = $(".select-room-btn");
    var roomItemContainer = $(".room-select-item");
    var roomCloseContainer = $(".room-list-close");
    var meetingTypeCloseBtn = $(".btn-close",".meeting-type.active");
    var addOffsiteBtn = $("#add-offsite-btn");
    var roomFilterInsertLocation = $(".room-filter-location");
    var selectActivityModal = $(".modal-select-activity")
    var meetingActivityContainer = $("#activity-meeting");
    var showingModal = false;
    var filterWidgetBuilt = false;
    var activitySettings = {};
    var offsiteEnabled = false;
    var notificationModal = $(".notification-modal");
    var offsiteMaximumDuration, offsiteMinimumDuration;
    var meetingMaximumDuration, meetingMinimumDuration;
    var showOverlay = false;
    var selectedActivityUuid = null;
    var selectedRoom = null;
    var selectedOffsite = null;
    var addOffsiteSelector = '.room-select-list .room-select-add';
    var alreadyHasSelectedOffsite = false;

    function setupUI() {
      $.validator.setDefaults({
          onkeyup: false,
          onsubmit: false,
          highlight: function(element) {
              $(element).closest('.form-group').addClass('has-error');
          },
          unhighlight: function(element) {
              $(element).closest('.form-group').removeClass('has-error');
              $(element).siblings('.help-block').hide();
          },
          errorElement: 'span',
          errorClass: 'help-block',
          onfocusout: function(element) {
              if ( !this.checkable( element ) && ( element.name in this.submitted || !this.optional( element ) ) ) {
                  this.element( element );
              }
          },
          showErrors: function(errorMap, errorList) {
              for (var i = 0, elements = this.validElements(); elements[ i ]; i++ ) {
                  this.settings.unhighlight.call( this, elements[ i ], this.settings.errorClass, this.settings.validClass );
                  $("#" + elements[ i ].name+ "-error").hide();
              }
              for (var j = 0, errorItem; errorList[ j ]; j++ ) {
                  errorItem = errorList[ j ];
                  this.settings.highlight(errorItem.element);
                  $("#" + errorItem.element.name+ "-error").show();
                  this.showLabel(errorItem.element, errorItem.message);
              };
          },
          errorPlacement: function(error, element) {
              if(element.parent('.input-group').length) {
                  error.insertAfter(element.parent());
              } else {
                  error.insertAfter(element);
              }
          },
          messages: {
              offsiteName: {
                  required: i18n.t("is_required", { attr: i18n.t('name') })
              },
              offsiteAddress: {
                  required: i18n.t("is_required", { attr: i18n.t('address') })
              }
          },
      });
    }

    function setupListeners() {
      meetingStore.listen(function(data) {
        if (data.isCapicityFilter) {
          showRoomsForActivity(true, data.lastAttendeeUuid);
          return;
        }
        if (data.success) {
          if (data.first_load) {
            setTimeout(function() {
              scheduler.updateView();
            }, 100);

            setAvailableActivities(data);
            var activityType = meetingInfo && meetingInfo.request && meetingInfo.request.activity;
            showOverlay = Store.MeetingStore.showOverlay;
            if (_.isEmpty(activityType)) {
              if (showOverlay) {
                showSelectActivityIfNew();
              } else {
                selectActivityMeeting();
              }
            } else {
              var roomDetails = meetingInfo.request.room;
              if (roomDetails) {
                selectedActivityUuid = activityType.uuid;
                selectActivityMeeting();
                if (roomDetails.uuid) {
                  selectedRoom = roomDetails;
                  selectSpecificRoom(selectedRoom.uuid);
                  MeetingActions.editRoom(selectedActivityUuid, meetingInfo.request.room);
                } else {
                  if (roomDetails.offsite_location_address !== undefined) {
                    selectedOffsite = { name: roomDetails.offsite_location_name, address: roomDetails.offsite_location_address };
                    selectSpecificOffsite();
                    alreadyHasSelectedOffsite = true;
                    MeetingActions.offsiteChosen(selectedOffsite);
                  }
                }
              }
            }

          } else {
            if (data.isNewEvent) {
              setAvailableActivities(data);
              setDefaultActivityRooms();
              if (selectedRoom) {
                selectSpecificRoom(selectedRoom.uuid);
              } else {
                if (selectedOffsite) {
                  selectSpecificOffsite();
                }
              }
            }
          }
          scheduler.config.offsite_enabled = data.configs.offsite_enabled;
          scheduler.config.can_book_offsite = data.configs.can_book_offsite;
          scheduler.config.can_book_room = data.configs.can_book_room;
          updateTopRoomLabel();


          if (data.configs.offsite_enabled) {

            if (data.configs.can_book_offsite) {
              if (alreadyHasSelectedOffsite) {
                $(addOffsiteSelector).addClass('hide');
              } else {
                if (selectedOffsite === null) {
                  $(addOffsiteSelector).removeClass('hide');
                }
              }
            } else {
              $(addOffsiteSelector).addClass('hide');
              if (selectedOffsite) {
                removeSelectedOffsite();
              }
            }
          }
          scheduler.updateView();
        }
      });

      $(meetingContainer).on('click', '.remove-selected-offsite', removeSelectedOffsite);
      $(meetingContainer).on('click', '.selected-offsite', openOffsiteLocation);

      $(meetingContainer).on('click', '.remove-selected-room', removeSelectedRoom);
      $(meetingContainer).on('click', '.reset-selection', resetOffsiteSelection);
      $('.room-select-list').on('click', '.add-offsite-location', addLocation);
      $(roomContainer).on('click', '.select-room-btn', selectRoom);
      $(".apply-room-filter").on('click', applyFilters);
      $(".reset-room-filter").on('click', resetFilters);
      $(offsiteLocationContainer).on('click', addOffsiteBtn.selector, addOffsite);
      $('#room-information').on('show.bs.modal', function (e) {
          showingModal = true;
      });

      $('#room-information').on('hidden.bs.modal', function (e) {
          showingModal = false;
      });

      $(offsiteLocationContainer).on('click', '.cancel', function(e) {
          e.preventDefault();
          e.stopPropagation();
          resetOffsiteContainer();
          showContainer(roomContainer);
          if (!selectedOffsite && !selectedRoom) {
            MeetingActions.offsiteChosen(null);
          }
      });

      $(".room-filter-location").on('change', '.filter-cb', function(e){
          e.stopPropagation();
          var checkbox = $(this);
          var value = checkbox.val();
          var state = checkbox.prop('checked');
          MeetingActions.updateFilter(value, state);
      });

      roomSearchBox.on('keyup', _.debounce(searchRooms, 369));
      roomFilterSearch.on('keyup', _.debounce(searchRooms, 369));

      meetingActivityContainer.on('click', selectMeetingActivity);
    }

    function updateTopRoomLabel() {
      var roomLabeLocaleKey;
      if (!selectedOffsite && !selectedRoom) {
        if (!!window.isEBCEvent) {
          roomLabeLocaleKey = i18n.t("briefing_center");
        } else {
          var keys = [];
          if (scheduler.config.can_book_room) {
              keys.push(i18n.t('room'));
          }
          if (scheduler.config.can_book_offsite) {
              keys.push(i18n.t('offsite'));
          }
          roomLabeLocaleKey = keys.join(', ');
        }
        $("#room-label").html(roomLabeLocaleKey);
      }
    }

    function setAvailableActivities(data) {
      var html = HandlebarsTemplates['book/meeting_type_item']({types:data.data.activities});
      meetingContainer.html(html);
    }

    function setDefaultActivityRooms() {
      selectedActivityUuid = $('.meeting-type:first-child').data('uuid');
      meetingStore.currentActivityUuid = selectedActivityUuid;
      showRoomsForActivity();
    }

    function setDefaultActivitySettings() {
      activitySettings = meetingStore.getActivitySettings(selectedActivityUuid);
      var timeSlot;
      _.forEach(activitySettings, function(value, key) {
        switch(key) {
          case 'min_duration': meetingMinimumDuration = Number(value) || 15; break;
          case 'max_duration': meetingMaximumDuration = Number(value) || 30; break;
          case 'time_slot': timeSlot = Number(value) || 15; break;
          case 'offfsite_enabled': offsiteEnabled = (value == 'yes'); break;
          case 'show_activity_overlay': showOverlay = (value == 'yes'); break;
          case 'offsite_min_duration': offsiteMinimumDuration = Number(value) || 15; break;
          case 'offsite_max_duration': offsiteMaximumDuration = Number(value) || 30; break;
          default: break;
        }
      });
      scheduler.config.minimum_duration = meetingMinimumDuration;
      scheduler.config.event_duration = meetingMaximumDuration;
      scheduler.config.meetingMaximumDuration = meetingMaximumDuration;
      scheduler.config.meetingMinimumDuration = meetingMinimumDuration;
      scheduler.config.offsiteMaximumDuration = offsiteMaximumDuration;
      scheduler.config.offsiteMinimumDuration = offsiteMinimumDuration;
      scheduler.config.time_step = timeSlot;
      scheduler.config.offsite_enabled = offsiteEnabled;

    }

    function showRoomsForActivity(isCapicityFilter, lastAttendeeUuid) {
      var rooms = meetingStore.getActivityRooms(selectedActivityUuid);
      rooms = _.filter( rooms, function(room) {
        var isRoomBigEnough = (room.capacity >= meetingStore.attendeeCount);
        if (selectedRoom && (selectedRoom.uuid === room.uuid) ) {
          room.hide = 'hide';
          if (isRoomBigEnough) {
            selectedRoom = room;
          } else {
            notificationModal.notificationModal({
              body: i18n.t('room_capacity_exceeded'),
              title: i18n.t('room_capacity_exceeded_title'),
              type: 'notification',
              class: 'red',
              dismiss: function() {
                AttendeeActions.unselectAttendee(lastAttendeeUuid);
              }
            });
          }
        } else {
          room.hide = '';
        }
        return isRoomBigEnough;
      });
      var html = HandlebarsTemplates['book/room_item']({
        rooms: rooms,
        hasRooms: (rooms.length > 0),
        enable_offsite: offsiteEnabled
      });
      roomContainer.html(html);
      if (!isCapicityFilter) {
        showAllRooms();
      }
      attachRoomHover(rooms);
    }

    function showAllRooms() {
      showContainer(roomContainer);
      hideContainer(offsiteLocationContainer);
    }

    function selectSpecificRoom(roomUuid) {
      var room = meetingStore.getSpecificRoom(roomUuid, selectedActivityUuid);
      if (room) {
        var html = HandlebarsTemplates['book/selected_room_done'](room);
        meetingContainer.html(html);
        unhighlightOtherRooms(roomUuid);
        showContainer(meetingContainer);
        selectedRoom = room;
        return room;
      } else {
        showAllRooms();
        selectedRoom = null;
      }
    }
    function unhighlightOtherRooms(uuid) {
      $('.room-select-item[data-uuid="'+ uuid +'"]').addClass('hide');
    }
    function highlightOtherRooms(uuid) {
      $('.room-select-item[data-uuid="'+ uuid +'"]').removeClass('hide');
    }

    function attachRoomHover(rooms) {
      var roomTooltipTemplate = HandlebarsTemplates['book/room_tooltip'];
      var roomHash = {};
      rooms.forEach(function(room) {
        roomHash[room.uuid] = room;
      });

      $('.room-select-item:not(.hide)').map(function() {
        var roomUuid = $(this).data('uuid');
        var roomData = roomHash[roomUuid];
        roomData.lastUpdatedOn = new Date(roomData["updated_on"]).toDateTime();
        $(this).popover({
          html: "true",
          template: "<div class='popover room-tooltip' role='tooltip'><div class='popover-content'></div></div>",
          content: roomTooltipTemplate(roomData),
          trigger: 'hover',
          placement: 'right'
        });
      });
    }

    function selectMeetingActivity(e) {
      e.preventDefault();
      e.stopPropagation();
      selectActivityModal.modal("hide");
      updateViewLabels(i18n.t("meeting"));
      selectActivityMeeting();
    }

    function selectActivityMeeting() {
      setDefaultActivityRooms();
      setDefaultActivitySettings();
    }

    function showSelectActivityIfNew() {
      if(meetingInfo && meetingInfo.request && meetingInfo.request.mode === "new") {
        selectActivityModal.modal();
      }
    }

    function updateViewLabels(label) {
      var branding_title = i18n.t("branding_title", {count : label});
      var section_title = i18n.t("section_title", {count : label});
      $("a.navbar-brand.meeting-title").html(branding_title);
      $("span.section-title",".calendar-section").html(section_title)
    }

    function applyFilters(e) {
      e.preventDefault();
      e.stopPropagation();
      MeetingActions.applyFilter();
      $('.filter-dropdown .dropdown-toggle').dropdown("toggle");
    }

    function resetFilters(e) {
      e.preventDefault();
      e.stopPropagation();
      MeetingActions.resetFilter();
      roomFilterSearch.val('');
      $(".filter-cb", ".room-filter-location").prop("checked",false);
      $('.filter-dropdown .dropdown-toggle').dropdown("toggle");
    }

    function searchRooms() {
      hideContainer(roomContainer);
      MeetingActions.searchRoom($(this).val());
    }

   function selectRoom(e) {
      if (e) {
        e.preventDefault();
        e.stopPropagation();
      }
      if (selectedRoom !== null) {
        resetRoomSelection();
      } else {
        if (selectedOffsite !== null) {
          $(addOffsiteSelector).removeClass('hide');
        }
      }
      var widget = $(this);
      var uuid = widget.data("uuid");
      selectSpecificRoom(uuid);

        MeetingActions.roomChosen(selectedActivityUuid, selectedRoom);
   }

   function addOffsite(e) {
      e.preventDefault();
      e.stopPropagation();
      var form = $("form", offsiteLocationContainer);
      var offsiteName = $("#name", form).attr('name', 'offsiteName');
      var offsiteAddress = $("#address", form).attr('name', 'offsiteAddress');
      form.validate();
      if (form.valid()) {
        if (selectedRoom) {
          resetRoomSelection();
        }
        selectedOffsite = { name: offsiteName.val(), address: offsiteAddress.val() };
        selectSpecificOffsite();
        resetOffsiteContainer();
        MeetingActions.offsiteChosen(selectedOffsite);
      }
   }

   function selectSpecificOffsite() {
    var html = HandlebarsTemplates['book/offsite_selection'](selectedOffsite);
    meetingContainer.html(html);
    $(addOffsiteSelector).addClass('hide');
   }

    function resetOffsiteContainer() {
      $("input", offsiteLocationContainer).val("");
      hideContainer(offsiteLocationContainer);
      showContainer(roomContainer);
      var validator = offsiteLocationContainer.find('form').validate();
      validator.resetForm();
      validator.reset();
      $(".form-group", offsiteLocationContainer).removeClass("has-error")
      $('.help-block', offsiteLocationContainer).show();
    }

   function removeSelectedOffsite(e) {
    if (e) {
      e.preventDefault();
      e.stopPropagation();
    }
    MeetingActions.offsiteChosen(null);
    !checkIfOffsiteInProgress() && showAllRooms();
    resetOffsiteData();
  }

  function resetOffsiteData() {
    selectedOffsite = null;
    meetingContainer.empty();
    $(addOffsiteSelector).removeClass('hide');
    alreadyHasSelectedOffsite = false;
  }

   function resetOffsiteSelection(e) {
      if (e) {
        e.preventDefault();
        e.stopPropagation();
      }
      resetOffsiteData();
      showContainer(offsiteLocationContainer);
      hideContainer(roomContainer);
   }

    function removeSelectedRoom(e) {
      if (e) {
        e.preventDefault();
        e.stopPropagation();
      }
      MeetingActions.roomChosen(selectedActivityUuid, null);
      MeetingActions.offsiteChosen(null);
      resetRoomSelection();
      checkIfOffsiteInProgress();
    }
    function checkIfOffsiteInProgress() {
      if ( !offsiteLocationContainer.hasClass('hide') ) {
        hideContainer(roomContainer);
        return true;
      }
    }

    function resetRoomSelection() {
      var uuid = selectedRoom.uuid;
      selectedRoom = null;
      meetingContainer.empty();
      highlightOtherRooms(uuid);
    }

    function addLocation(e) {
        e.preventDefault();
        e.stopPropagation();
        hideContainer(roomContainer);
        showContainer(offsiteLocationContainer);
    }
    function openOffsiteLocation(e) {
      addLocation(e);
      $("#name", offsiteLocationContainer).val(selectedOffsite['name']);
      $("#address", offsiteLocationContainer).val(selectedOffsite['address']);
    }
    function init() {
        setupUI();
        setupListeners();
        MeetingActions.getAllMeetingTypes(true);
    }

    function hideContainer(container) {
        container.addClass("hide");
    }

    function showContainer(container) {
        container.removeClass("hide");
    }

    return {
        init: init
    }

}());

module.exports = MeetingTypeHandler;



}).call(this,require('_process'),typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {},require("buffer").Buffer,arguments[3],arguments[4],arguments[5],arguments[6],"/app/scripts/Book/MeetingType/handler.js","/app/scripts/Book/MeetingType")
},{"../Attendee/actions":2,"../Calendar/actions":7,"./actions":14,"./store":16,"_process":28,"buffer":24}],16:[function(require,module,exports){
(function (process,global,Buffer,__argument0,__argument1,__argument2,__argument3,__filename,__dirname){
var MeetingTypeActions = require("./actions");
var AttendeeActions = require("../Attendee/actions");
var Api = require('common_api');

var MeetingStore = Reflux.createStore({

    init: function () {
        this.listenToMany(MeetingTypeActions);
        this.meetingTypes = {}
        this.selectedMeetingType = {};
        this.selectedRoom = {};
        this.searchText = "";
        this.attendeeCount = 0;
        this.filters = [];
        this.showOverlay = false;
        this.activityRoomHash = {};
        this.activitySettingsHash = {};
        this.currentActivityUuid = null;
    },
    onUpdateFilter: function(value, state) {
        var filter = this.filters;
        if(state) {
            filter.push(value);
        } else {
            var index = filter.indexOf(value);
            if(index > -1) {
                filter.splice(index, 1);
            }
        }
    },
    onApplyFilter: function(){
        this.onGetAllMeetingTypes();
    },
    onResetFilter: function() {
        this.filters = [];
        this.searchText = '';
        this.onGetAllMeetingTypes();
    },
    setActivityRooms : function(uuid, rooms) {
        this.activityRoomHash[uuid] = rooms;
    },
    getActivityRooms: function(uuid) {
        var activityRooms = this.activityRoomHash[uuid];
        return (activityRooms instanceof Array) ? activityRooms.slice() : [];
    },
    setActivitySettings: function(uuid, settings) {
        this.activitySettingsHash[uuid] = settings;
        this.showOverlay = this.showOverlay || (settings.show_activity_overlay === "yes");
    },
    getActivitySettings: function(uuid) {
        return this.activitySettingsHash[uuid];
    },
    showAvailableRooms: function(attendeeCount, lastAttendeeUuid) {
        this.attendeeCount = attendeeCount;
        this.trigger({ isCapicityFilter: true, lastAttendeeUuid: lastAttendeeUuid });
    },
    onGetAllMeetingTypes: function(isFirstLoad, isNewEvent) {
        var params = {};
        if(this.currentEvent) {
            var start = this.currentEvent.start_date.getHours() * 60 + this.currentEvent.start_date.getMinutes();
            var end  = this.currentEvent.end_date.getHours() * 60 + this.currentEvent.end_date.getMinutes();
            params['event_date'] = moment(this.currentEvent.start_date).format("DD-MM-YYYY");
            params['start_time'] = start;
            params['end_time'] = end;
        }
        if (meetingInfo.request.mode === "edit") {
            params['meeting_request'] = meetingInfo.request.uuid;
        }
        if(typeof location_uuid != "undefined") {
            params['location_uuid'] = location_uuid;
        }
        var promise = Api.fetch({
            url: Api.ENDPOINTS.room_activities,
            data: params
        });
        promise.then(function(data){
            var meetingTypeData = data.data.activities;
            var configs = data.data.room_offsite_configs;
            this.meetingTypes = meetingTypeData;
            data.isCapicityFilter = false;
            _.forEach(this.meetingTypes, function(meetingType, index){
                meetingType['hide'] = '';
                this.setActivitySettings(meetingType.uuid, meetingType.settings);
                if(this.filters.length > 0) {
                  if(_.includes(this.filters,meetingType.display_name) === false) {
                    meetingType['hide'] = 'hide';
                  }
                }
                meetingType.rooms = _.filter(meetingType.rooms, function(room) {
                    room.resources = _.pluck(room.facilities, "name");
                    room.mapped_meeting_types = _.pluck(room.activities, "name");
                    room.type = {};
                    return configs.can_book_room && room.available;
                }.bind(this));
                this.setActivityRooms(meetingType.uuid, meetingType.rooms);

            }.bind(this));
            if (this.selectedMeetingType) {
                MeetingTypeActions.meetingTypeChosen(this.selectedMeetingType);
            }

            var keys = Object.keys(meetingTypeData);
            keys.forEach(function(key){
              var type = meetingTypeData[key];
              var count = _.filter(type.rooms, function(room) {return room.available}).length;
              type['count'] = count;
            }.bind(this));

            data.selectedMeetingType = this.selectedMeetingType;
            data.selectedRoom = this.selectedRoom;
            data.meeting_types = this.meetingTypes;
            data.first_load = isFirstLoad;
            data.isNewEvent = isNewEvent;
            data.configs = configs;
            this.trigger(data);
        }.bind(this));

        promise.catch(function(error) {
           this.trigger(error);
        }.bind(this));
    },
    getMeetingType: function(uuid) {
        return _.find(this.meetingTypes, function(type) {
            return type.uuid === uuid;
        });
    },
    getSpecificRoom: function(roomUuid, activityUuid) {
        var allRooms = this.getActivityRooms(activityUuid);
        return _.find(allRooms, function(room, index) {
            return room.uuid === roomUuid;
        });
    },
    getSelectedRoom: function(uuid,meetingTypeUuid) {
        var meetingType = this.selectedMeetingType;
        if(!this.selectedMeetingType.uuid)
            meetingType = this.getMeetingType(meetingTypeUuid);
        if(!meetingType && meetingTypeUuid) {
            meetingType = this.getMeetingType(meetingTypeUuid);
        }
        if(meetingType) {
            var rooms = meetingType.rooms || [];
            var selectedRoom = _.find(rooms, function(room){return room.uuid == uuid});
            return selectedRoom;
        }
        return {};
    },
    onMeetingTypeChosen: function(type) {
        this.selectedMeetingType = type;
        this.trigger({action: 'onMeetingTypeChosen', payload: type});
    },
    onRoomChosen: function(activityUuid, room) {
        this.selectedRoom = room;
        this.selectedMeetingType = this.getMeetingType(activityUuid);
        this.isOffsiteSelected = false;
        this.trigger({action:'onRoomChosen', payload: {type: this.selectedMeetingType, room: room, offsite:false}});
    },
    onSearchRoom: function(text) {
        this.searchText = text;
        MeetingTypeActions.getAllMeetingTypes();
    },
    onEditRoom: function(activityUuid, room) {
        this.selectedMeetingType = this.getMeetingType(activityUuid);
        this.selectedRoom = room;
        this.isOffsiteSelected = false;
        this.trigger({action:'onRoomChosen', payload: {type: this.selectedMeetingType, room: room, offsite:false }});
    },
    onOffsiteChosen: function(offsite) {
        this.selectedRoom = offsite;
        this.isOffsiteSelected = offsite !== null;
        this.trigger({action:'onRoomChosen', payload: {type: this.selectedMeetingType, room: offsite, offsite: true}});
    },
    onEventCreated: function(event) {
        this.currentEvent = event;
        this.onGetAllMeetingTypes(false, true);
    },
    isRoomBigEnough: function(selectedRoom) {
        return (this.attendeeCount <= selectedRoom.capacity);
    },
    onAttendeeCountChanged: function(count) {
        this.attendeeCount = count;
        var canSelectMore = true;
        if (this.selectedRoom && this.selectedRoom.capacity) {
            canSelectMore = this.attendeeCount < this.selectedRoom.capacity;
        }
        AttendeeActions.canSelectAttendees(canSelectMore);
    }
});


module.exports = {
    MeetingStore: MeetingStore
};



}).call(this,require('_process'),typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {},require("buffer").Buffer,arguments[3],arguments[4],arguments[5],arguments[6],"/app/scripts/Book/MeetingType/store.js","/app/scripts/Book/MeetingType")
},{"../Attendee/actions":2,"./actions":14,"_process":28,"buffer":24,"common_api":"common_api"}],17:[function(require,module,exports){
(function (process,global,Buffer,__argument0,__argument1,__argument2,__argument3,__filename,__dirname){
var FormViewRenderer = require('../../commons/form_view_renderer');
var Store = require('../MeetingInMaking/store');
var CustomFormStore = require('../MeetingInMaking/form_store');
var Actions = require('../MeetingInMaking/actions');
var MeetingTypeActions = require("../MeetingType/actions");
var MeetingTypeStore = require("../MeetingType/store");

var MeetingViewHandler = (function () {
    var mainContainer = $("#proceed-page");
    var proceedRoomContainer = $(".selected-room", mainContainer);
    var proceedTimeContainer = $(".selected-time", mainContainer);
    var proceedInternalContainer = $(".selected-internal-attendee .selected-attendee-list", mainContainer);
    var proceedExternalContainer = $(".selected-external-attendee .selected-attendee-list", mainContainer);
    var requestorSelect = $("#requestor-select");
    var dynamicFormContainer = $("#dynamic_form", mainContainer);
    var statusButton = $(".approved-text");
    var statusIndicator = $(".meeting-status");
    var acceptMeeting = $(".accept-meeting");
    var declineMeeting = $(".decline-meeting");

    var eventHandlers = {
        onAcceptDeclineMeeting: onAcceptDeclineMeeting
    }


    function init() {
        CustomFormStore.listen(updateCustomForm);
        Store.listen(function(data){
            var action = data.action;
            var payload = data.payload || {};
            var func = eventHandlers[action];
            if(func) {
                func(payload);
            }
        });
        Actions.getCustomForm();
        MeetingTypeActions.getAllMeetingTypes();
        var meeting = meetingInfo.request;
        var roomInfo = {};
        if (meeting.room.uuid) {
            roomInfo = { offsite: false, display_name: meeting.activity.display_name, room_name: meeting.room.name, capacity: meeting.room.capacity};
        } else {
            if (meeting.room.offsite_location_address) {
                roomInfo = { offsite: true, name: meeting.room.offsite_location_name, address: meeting.room.offsite_location_address };
            }
        }
        roomInfo.showGotoMainOptionFromDetails = false;

        var roomTemplate = HandlebarsTemplates['book/proceed_room'];
        $(proceedRoomContainer).html(roomTemplate(roomInfo));

        var proceedTemplate = HandlebarsTemplates['book/proceed_time'];
        var start = new Date(meeting.start_time);
        var end = new Date(meeting.end_time);

        var start_time = new Date(start.getTime()+start.getTimezoneOffset() * 60000);
        var end_time = new Date(end.getTime()+end.getTimezoneOffset() * 60000);

        var event_date = start.toMediumDate();
        start = moment(start_time).format('hh:mm A');
        end = moment(end_time).format('hh:mm A');

        // pvrcs: Fixed header text while meeting viewing and editing flows in book meeting.
        $('.book-meeting .meeting-id').removeAttr("data-i18n").text(i18n.t("meeting_id") + meeting.id);
        html = proceedTemplate({start_time:start, end_time:end,event_date:event_date, showGotoMainOptionFromDetails: false});
        proceedTimeContainer.html(html);

        var template = HandlebarsTemplates['book/selected_attendee'];
        var internalHtml = template({users:meeting.users.internal, remove:false});
        proceedInternalContainer.html(internalHtml);
        var externalHtml = template({users:meeting.users.external, remove:false});
        proceedExternalContainer.html(externalHtml);


        var internalCount = meeting.users.internal.length,
            externalCount = meeting.users.external.length;
        $(".selectedInternalAttendeeCount").text(internalCount);
        $(".selectedInternalAttendeeCount + span").html( i18n.t( (internalCount == 1) ? 'internal_participant' : 'internal_participants') );
        $(".selectedExternalAttendeeCount").text(externalCount);
        $(".selectedExternalAttendeeCount + span").html( i18n.t( (externalCount == 1) ? 'external_participant': 'external_participants') );

        var roomFullHolder = $("#roomFullHolder"),
            occupiedRoomHolder = $("#occupiedRoomHolder"),
            availableRoomCount = roomInfo.capacity - (internalCount + externalCount);

        if (availableRoomCount <= 0) {
            roomFullHolder.removeClass('hide');
            occupiedRoomHolder.addClass('hide');
        } else {
            roomFullHolder.addClass('hide');
            occupiedRoomHolder.removeClass('hide').find('.occupiedCount').text(availableRoomCount);
        }
        var requestor = meeting.requestor;
        var option = $("<option/>").val(requestor.uuid).html(requestor.first_name + " " + requestor.last_name);
        option.prop("selected","selected");

        requestorSelect.empty();
        requestorSelect.append(option);

        requestorSelect.prop('disabled','disabled');

        _updateAcceptDecline(meeting.actions);
        statusButton.text(meeting.status);
        statusIndicator.addClass(meeting.status);

        $(".go-to-main").hide();

        // hide add button for attendees
        $('.go-to-main-internal').addClass('hide');
        $('.go-to-main-external').addClass('hide');

        acceptMeeting.on('click', 'a', onAcceptMeeting);
        declineMeeting.on('click', 'a', onDeclineMeeting);
    }

    function onAcceptMeeting(e) {
      e.preventDefault();
      e.stopPropagation();
      var currentUser = envDetails.currentUser.uuid;
      Actions.acceptMeeting(meetingInfo.request.uuid, currentUser);
    }

    function onDeclineMeeting(e) {
      e.preventDefault();
      e.stopPropagation();
      var currentUser = envDetails.currentUser.uuid;
      Actions.declineMeeting(meetingInfo.request.uuid, currentUser);
    }

    function onAcceptDeclineMeeting(payload) {
      var actions = payload.data.actions;
      _updateAcceptDecline(actions);
      var accepted = false;
      if(actions.length === 1 && actions[0] === i18n.t('decline'))
        accepted = true;
      var title = (accepted === true) ? "accepted" : "declined";
      var message = (accepted === true) ? "accepted_msg" : "declined_msg";
      $(".notification-modal").notificationModal({
        title: i18n.t(title),
        body: i18n.t(message)
      });
      setTimeout(function(){
        window.location.href = envDetails['urlPrefix'] + "/meeting_list";
      }, 2 * 1000);
    }


    function _updateAcceptDecline(actions) {
      acceptMeeting.addClass("hide");
      declineMeeting.addClass("hide");
      if(actions.length === 2) {
        acceptMeeting.removeClass("hide");
        declineMeeting.removeClass("hide");
      } else {
        if(actions.length === 1 && actions[0] === i18n.t('decline')) {
          declineMeeting.removeClass("hide");
          accepted = true;
        }
      }


    }

    function updateCustomForm(data) {
        if(data && data.custom_form_fields) {
            var fields = meetingInfo.request.custom_fields || {};
            fields['meeting_with'] = meetingInfo.request.meeting_with;
            formRenderer = $(dynamicFormContainer).formViewRenderer({fieldCollection:data.custom_form_fields});
            formRenderer.init();
            if(meetingInfo.request) {
                meetingInfo.request.custom_fields = meetingInfo.request.custom_fields || {};
                formRenderer.setValues(meetingInfo.request)
            }
        }
    }

    return {
        init: init
    };
})();

module.exports = MeetingViewHandler;



}).call(this,require('_process'),typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {},require("buffer").Buffer,arguments[3],arguments[4],arguments[5],arguments[6],"/app/scripts/Book/MeetingView/handler.js","/app/scripts/Book/MeetingView")
},{"../../commons/form_view_renderer":23,"../MeetingInMaking/actions":10,"../MeetingInMaking/form_store":11,"../MeetingInMaking/store":13,"../MeetingType/actions":14,"../MeetingType/store":16,"_process":28,"buffer":24}],18:[function(require,module,exports){
(function (process,global,Buffer,__argument0,__argument1,__argument2,__argument3,__filename,__dirname){
var AccountActions = Reflux.createActions([
    'fetchAccounts',
    'fetchOppoprunity'
]);


module.exports = AccountActions;



}).call(this,require('_process'),typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {},require("buffer").Buffer,arguments[3],arguments[4],arguments[5],arguments[6],"/app/scripts/Book/SfdcAccount/actions.js","/app/scripts/Book/SfdcAccount")
},{"_process":28,"buffer":24}],19:[function(require,module,exports){
(function (process,global,Buffer,__argument0,__argument1,__argument2,__argument3,__filename,__dirname){
var AccountActions = require('./actions');
var AttendeeStore = require('../Attendee/store').AttendeeStore;
var AccountStore = require('./store');

var AccountHandler = (function () {
  var containerEl = $('#account-opportunity');
  var accountChosen = containerEl.find("#select_account");
  var opportunityChosen = containerEl.find("#select_opportunity");

  var defaultAccount, defaultOppty = {};

  function init(){

    if(!containerEl.length)
      return;

    defaultAccount = AccountStore.selectedAccount;
    defaultOppty = AccountStore.selectedOpportunity;

    if(meetingInfo.request.mode === 'edit'){
      initAccountSelect2("-1", meetingInfo.request.meeting_with);
      initOpptySelect2("", "");

      accountChosen.attr("disabled", "disabled");
      opportunityChosen.attr("disabled", "disabled");
    } 
    else {
      initAccountSelect2(defaultAccount.id, defaultAccount.name); 
      if(AccountStore.selectedAccount.id){
        showActiveAccountOppty(AccountStore.selectedAccount.id);
      }
      else {
        initOpptySelect2(defaultOppty.id, defaultOppty.name);
      } 
    }

    containerEl.on("change", "#select_account", function(e, isOpptySelected){
      var selectedEl = $(this).find('option:selected');
      AccountStore.updateAccountSelection(selectedEl.val(), selectedEl.text());
      //Oppty has been already selected.
      if(!isOpptySelected){
        showActiveAccountOppty(selectedEl.val());  
      }
      AttendeeStore.onAllExternalAttendeeUnselected();
      AttendeeStore.resetExternalList();
      AttendeeStore.onFetchExternal(1);
    });

    containerEl.on("change", "#select_opportunity", function(e){
      var selectedEl = $(this).find('option:selected');
      if(selectedEl.length){
        AccountStore.updateOpptySelection(selectedEl.val(), selectedEl.text());
        if(!AccountStore.selectedAccount.id){
          var data = AccountStore.getAccountInfo(selectedEl.val());
          initAccountSelect2(data.accountid, data.accountname, true);
        }
        
      }
    });
  };

  function renderOpptyArray(data){
    var results = $.map(data, function(oppty){
      return { id: oppty.id, text: oppty.name };
    });
    opportunityChosen.find('option').remove();
    var select2OpptyEl = opportunityChosen.select2({
      initSelection: function(el, callback){
        if(AccountStore.selectedOpportunity.id){
          callback(_.find(results, { id: AccountStore.selectedOpportunity.id }));
        }
      },
      data: results,
      allowClear: true,
      placeholder: "Select an Opportunity"
    });

    select2OpptyEl.trigger("change");
  };

  function showActiveAccountOppty(id){
    if(AccountStore.getOpptyList(id)){
      var data = AccountStore.getOpptyList(id)['opty'];
      renderOpptyArray(data);
    }
    else {
      AccountStore.onFetchAccounts({id: id, name: ''}).then(function(response){
        renderOpptyArray(response[0]['opty']);
      });
    }
  };

  function initAccountSelect2(initID, initName, isOpptySelected){
    var accSelectEl = accountChosen.select2({
      ajax: {
        data: function (params) {
          var queryParameters = { id: "", name: params.term };
          return queryParameters;
        },
        transport: function (params, success, failure) {
          var $request = AccountStore.onFetchAccounts(params.data);
          $request.then(success);
          $request.catch(failure);
          return $request;
        },
        processResults: function (data) {
          //Store current searched account details.
          AccountStore.storeAccountDetails(data);
          var results = $.map(data, function(account){
            return { id: account.id, text: account.name };
          });
          return {
            results: results
          };
        },
      },
      initSelection: function (element, callback) {
        element.html($('<option/>').val(initID).text(initName));
        callback({ id: initID, text: initName });
      },
      allowClear: true,
      minimumInputLength: 3,
      placeholder: "Select an Account",
    });

    if(isOpptySelected){
      accSelectEl.trigger("change", isOpptySelected);
    }
  };

  function initOpptySelect2(initID, initName){
    opportunityChosen.select2({
      ajax: {
        minimumInputLength: 3,
        data: function (params) {
          var queryParameters = { id: "", name: params.term };
          return queryParameters;
        },
        transport: function (params, success, failure) {
          var $request = AccountStore.onFetchOppoprunity(params.data);
          $request.then(success);
          $request.catch(failure);
          return $request;
        },
        processResults: function (data) {
          AccountStore.storeOpptyDetails(data);

          var results = $.map(data, function(account){
            return { id: account.id, text: account.name };
          });
          return {
            results: results
          };
        },
      },
      initSelection: function (element, callback) {
        callback({ id: initID, text: initName });
      },
      allowClear: true,
      minimumInputLength: 3,
      placeholder: "Select an Opportunity",
    });
  };

  return {
    init: init
  };

}());

module.exports = AccountHandler;



}).call(this,require('_process'),typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {},require("buffer").Buffer,arguments[3],arguments[4],arguments[5],arguments[6],"/app/scripts/Book/SfdcAccount/handler.js","/app/scripts/Book/SfdcAccount")
},{"../Attendee/store":4,"./actions":18,"./store":20,"_process":28,"buffer":24}],20:[function(require,module,exports){
(function (process,global,Buffer,__argument0,__argument1,__argument2,__argument3,__filename,__dirname){
var AccountActions = require("./actions");
var Api = require('common_api');

var AccountStore = Reflux.createStore({

  init: function () {
      this.listenToMany(AccountActions);
      this.selectedAccount = {
        id: this.urlParam('accid'),
        name: decodeURIComponent(this.urlParam('accname')).replace(/\+/g, ' '),
      };
      this.selectedOpportunity = {
        id: this.urlParam('oppid'),
        name: decodeURIComponent(this.urlParam('oppname')).replace(/\+/g, ' '),
      };
      this.localAccounts = {};
      this.localOpportunity = {};
  },

  getAccountInfo: function(id){
    return this.localOpportunity[id];
  },

  getOpptyList: function(id){
    return this.localAccounts[id];
  },

  storeOpptyDetails: function(opptys){
    var result = {};
    _.forEach(opptys, function(oppty){
      result[oppty.id] = oppty;
    });

    this.localOpportunity = result;
  },

  storeAccountDetails: function(accounts){
    var result = {};
    _.forEach(accounts, function(account){
      result[account.id] = account;
    });

    this.localAccounts = result;
  },

  urlParam: function(name){
    var results = new RegExp('[\?&]' + name + '=([^&#]*)').exec(window.location.href);
    if (results==null){
       return "";
    }
    else{
       return results[1] || 0;
    }
  },

  updateAccountSelection: function(id, name){
    this.selectedAccount = { id: id, name: name };
  },

  updateOpptySelection: function(id, name){
    this.selectedOpportunity = { id: id, name: name };
  },

  onFetchAccounts: function(request) {
    var promise = Api.fetch({
      data: request,
      url: Api.ENDPOINTS.fetch_account
    });
    
    return promise;
  },

  onFetchOppoprunity: function(request) {
    var promise = Api.fetch({
      data: request,
      url: Api.ENDPOINTS.fetch_opportunity,
    });
    
    return promise;
  }
});


module.exports = AccountStore;


}).call(this,require('_process'),typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {},require("buffer").Buffer,arguments[3],arguments[4],arguments[5],arguments[6],"/app/scripts/Book/SfdcAccount/store.js","/app/scripts/Book/SfdcAccount")
},{"./actions":18,"_process":28,"buffer":24,"common_api":"common_api"}],21:[function(require,module,exports){
(function (process,global,Buffer,__argument0,__argument1,__argument2,__argument3,__filename,__dirname){
// var i18n = require('i18next-client');

var defaults = {
        textfield: {
            widget: "textfield",
            label:i18n.t("unnamed"),
            type:"textfield",
            field_name: "{{prefix}}{{_id}}",
            required: true,
            placeholder: i18n.t("unnamed"),
            helpText: "",
            values: '',
            canDelete: true,
        },
        datefield: {
            widget: "textfield",
            label:i18n.t("unnamed"),
            type:"datefield",
            field_name: "{{prefix}}{{_id}}",
            required: true,
            placeholder: i18n.t("choose_date"),
            helpText: "",
            values:"",
            canDelete: true,
            postInstantiate: function(cloned) {
                setTimeout(function(){
                    $("#"+cloned.field_name).datepicker();
                },20);
            },
        },
        checkbox: {
            widget: "checkbox",
            label:i18n.t("enter_valid_text"),
            field_name: "{{prefix}}{{_id}}",
            required: true,
            placeholder: i18n.t("unnamed"),
            canDelete: true,
            type: 'checkbox'
        },
        textarea: {
            widget: "textarea",
            label:i18n.t("unnamed"),
            field_name: "{{prefix}}{{_id}}",
            required: true,
            placeholder: i18n.t("unnamed"),
            helpText: "",
            canDelete: true,
            type: 'textarea',
            values: "",
        },
        dropdown: {
            widget: "dropdown",
            label:i18n.t("unnamed"),
            field_name: "{{prefix}}{{_id}}",
            required: true,
            pleaseSelect: true,
            values : [],
            helpText: "",
            canDelete: true,
            type: 'dropdown'
        },
        multiselect_dropdown: {
            widget: "multiselect_dropdown",
            label:i18n.t("unnamed"),
            field_name: "{{prefix}}{{_id}}",
            placeholder: i18n.t("select_something"),
            required: true,
            helpText: "",
            values: [],
            canDelete: true,
            type: 'multiselect_dropdown',
            postInstantiate: function(cloned) {
                setTimeout(function(){
                    $(".chosen-select").chosen({
                        width: "100%",
                        disable_search_threshold: 5
                    });
                },20);
            },
            afterChange: function(cloned) {
                setTimeout(function(){
                    $(".chosen-select").trigger("chosen:updated");
                },20);
            }
        },
}

module.exports = defaults;



}).call(this,require('_process'),typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {},require("buffer").Buffer,arguments[3],arguments[4],arguments[5],arguments[6],"/app/scripts/EventSetting/meeting/defaults.js","/app/scripts/EventSetting/meeting")
},{"_process":28,"buffer":24}],22:[function(require,module,exports){
(function (process,global,Buffer,__argument0,__argument1,__argument2,__argument3,__filename,__dirname){
(function($){
    var defaults = require("../EventSetting/meeting/defaults");

    var FormRenderer = function(container, settings) {

        function init() {
            if(settings.fieldCollection) {
                container.empty();
                var form = settings.fieldCollection.map(function(field){
                    var type = field.type || "textfield";
                    var defaultItem = defaults[type];
                    var templateName = "form_builder/"+type;
                    var template = HandlebarsTemplates[templateName];
                    var html = template(field);
                    if(defaultItem.postInstantiate) {
                        defaultItem.postInstantiate(field);
                    }
                    container.append(html);
                });
                $(".duplicate-remove-btn").addClass("hide");
            }
        }

        function getValues() {
            var customFormFields = {};
            $("input,select,textarea",container).each(function(index,element){
                var elem = $(element);
                var parent = elem.parent();
                var name = $(element).attr('name');
                var value;
                if(name !== undefined) {
                    if (parent.hasClass("checkbox")) {
                        value = elem.prop("checked");
                    } else {
                        value = elem.val();
                    }
                    customFormFields[name] = value;
                }
            });
            return customFormFields;
        }

        function setValues(meetingInfo) {
            meetingInfo.custom_fields["meeting_with"] = meetingInfo.meeting_with;
            var values = meetingInfo.custom_fields;
            var vals = values || {};
            var names = Object.keys(vals);

            $("input,select,textarea",container).each(function(index,element){
                var parent = $(element).parent();
                var name = $(element).attr('name');
                var value = vals[name] || '';
                if($(parent).hasClass("checkbox")) {
                    if(value === "true") {
                        $(element).prop("checked", "checked");
                    }
                } else {
                    $(element).val(value);
                    if(typeof jiffle !== 'undefined' && name === "meeting_with"){
                        $(element).attr("disabled", "disabled");
                    }
                }
            });
            $(".chosen-select").trigger("chosen:updated");

        }

        function setValue(name, value) {
            var element = $("[name=" + name + "]");
            var parent = element.parent();
            if(parent.hasClass("checkbox")) {
                if(value === "true") {
                    $(element).prop("checked", "checked");
                }
            } else {
                $(element).val(value);
                if(typeof jiffle !== 'undefined' && name === "meeting_with"){
                    $(element).attr("disabled", "disabled");
                }
            }
            $(".chosen-select").trigger("chosen:updated");

        }

        return {
            init: init,
            setValue: setValue,
            getValues: getValues,
            setValues: setValues
        }
    }

    $.fn.formRenderer = function(options) {
        var settings = $.extend({
        },options);
        return new FormRenderer($(this), settings);
    }

}(jQuery));



}).call(this,require('_process'),typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {},require("buffer").Buffer,arguments[3],arguments[4],arguments[5],arguments[6],"/app/scripts/commons/form_renderer.js","/app/scripts/commons")
},{"../EventSetting/meeting/defaults":21,"_process":28,"buffer":24}],23:[function(require,module,exports){
(function (process,global,Buffer,__argument0,__argument1,__argument2,__argument3,__filename,__dirname){
(function($){
    var defaults = require("../EventSetting/meeting/defaults");

    var FormViewRenderer = function(container, settings) {

        function init() {
            if(settings.fieldCollection) {
                container.empty();
                var form = settings.fieldCollection.map(function(field){
                    var type = field.type || "textfield";
                    var defaultItem = defaults[type];
                    var templateName = "form_builder/view_field";
                    var template = HandlebarsTemplates[templateName];
                    var html = template(field);
                    container.append(html);
                });
                $(".duplicate-remove-btn").addClass("hide");
            }
        }

        function getValues() {
            var customFormFields = {};
            $("input,select,textarea",container).each(function(index,element){
                var elem = $(element);
                var parent = elem.parent();
                var name = $(element).attr('name');
                if(name !== undefined) {
                    var value = $(element).val() || '';
                    if($(parent).hasClass("checkbox"))
                        value = $(element).prop("checked");
                    var escaped = $("<div>").text(value).html();
                    customFormFields[name] = escaped;
                }
            });
            return customFormFields;
        }

        function setValues(meetingInfo) {
            meetingInfo.custom_fields["meeting_with"] = meetingInfo.meeting_with;
            var values = meetingInfo.custom_fields;
            var vals = values || {};

            $(".field-value-label", container).each(function(index, element) {
                var name = $(element).attr('name');
                var value = vals[name] || '';
                var escaped = $("<div>").text(value).html();
                $(element).html(escaped);
            });
            var multiselect = $(".field-value-list", container);
            var name = multiselect.attr('name');
            var innerHtml = "";
            _.forEach(vals[name], function(val, key) {
                var escaped = $("<div>").text(val).html();
                innerHtml += '<li>' + escaped + '</li>';
            });

            multiselect.html(innerHtml);
            $(".chosen-select").trigger("chosen:updated");

        }

        return {
            init: init,
            getValues: getValues,
            setValues: setValues
        }
    }

    $.fn.formViewRenderer = function(options) {
        var settings = $.extend({
        },options);
        return new FormViewRenderer($(this), settings);
    }

}(jQuery));



}).call(this,require('_process'),typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {},require("buffer").Buffer,arguments[3],arguments[4],arguments[5],arguments[6],"/app/scripts/commons/form_view_renderer.js","/app/scripts/commons")
},{"../EventSetting/meeting/defaults":21,"_process":28,"buffer":24}],24:[function(require,module,exports){
(function (process,global,Buffer,__argument0,__argument1,__argument2,__argument3,__filename,__dirname){
/*!
 * The buffer module from node.js, for the browser.
 *
 * @author   Feross Aboukhadijeh <feross@feross.org> <http://feross.org>
 * @license  MIT
 */

var base64 = require('base64-js')
var ieee754 = require('ieee754')
var isArray = require('is-array')

exports.Buffer = Buffer
exports.SlowBuffer = SlowBuffer
exports.INSPECT_MAX_BYTES = 50
Buffer.poolSize = 8192 // not used by this implementation

var rootParent = {}

/**
 * If `Buffer.TYPED_ARRAY_SUPPORT`:
 *   === true    Use Uint8Array implementation (fastest)
 *   === false   Use Object implementation (most compatible, even IE6)
 *
 * Browsers that support typed arrays are IE 10+, Firefox 4+, Chrome 7+, Safari 5.1+,
 * Opera 11.6+, iOS 4.2+.
 *
 * Due to various browser bugs, sometimes the Object implementation will be used even
 * when the browser supports typed arrays.
 *
 * Note:
 *
 *   - Firefox 4-29 lacks support for adding new properties to `Uint8Array` instances,
 *     See: https://bugzilla.mozilla.org/show_bug.cgi?id=695438.
 *
 *   - Safari 5-7 lacks support for changing the `Object.prototype.constructor` property
 *     on objects.
 *
 *   - Chrome 9-10 is missing the `TypedArray.prototype.subarray` function.
 *
 *   - IE10 has a broken `TypedArray.prototype.subarray` function which returns arrays of
 *     incorrect length in some situations.

 * We detect these buggy browsers and set `Buffer.TYPED_ARRAY_SUPPORT` to `false` so they
 * get the Object implementation, which is slower but behaves correctly.
 */
Buffer.TYPED_ARRAY_SUPPORT = (function () {
  function Bar () {}
  try {
    var arr = new Uint8Array(1)
    arr.foo = function () { return 42 }
    arr.constructor = Bar
    return arr.foo() === 42 && // typed array instances can be augmented
        arr.constructor === Bar && // constructor can be set
        typeof arr.subarray === 'function' && // chrome 9-10 lack `subarray`
        arr.subarray(1, 1).byteLength === 0 // ie10 has broken `subarray`
  } catch (e) {
    return false
  }
})()

function kMaxLength () {
  return Buffer.TYPED_ARRAY_SUPPORT
    ? 0x7fffffff
    : 0x3fffffff
}

/**
 * Class: Buffer
 * =============
 *
 * The Buffer constructor returns instances of `Uint8Array` that are augmented
 * with function properties for all the node `Buffer` API functions. We use
 * `Uint8Array` so that square bracket notation works as expected -- it returns
 * a single octet.
 *
 * By augmenting the instances, we can avoid modifying the `Uint8Array`
 * prototype.
 */
function Buffer (arg) {
  if (!(this instanceof Buffer)) {
    // Avoid going through an ArgumentsAdaptorTrampoline in the common case.
    if (arguments.length > 1) return new Buffer(arg, arguments[1])
    return new Buffer(arg)
  }

  this.length = 0
  this.parent = undefined

  // Common case.
  if (typeof arg === 'number') {
    return fromNumber(this, arg)
  }

  // Slightly less common case.
  if (typeof arg === 'string') {
    return fromString(this, arg, arguments.length > 1 ? arguments[1] : 'utf8')
  }

  // Unusual.
  return fromObject(this, arg)
}

function fromNumber (that, length) {
  that = allocate(that, length < 0 ? 0 : checked(length) | 0)
  if (!Buffer.TYPED_ARRAY_SUPPORT) {
    for (var i = 0; i < length; i++) {
      that[i] = 0
    }
  }
  return that
}

function fromString (that, string, encoding) {
  if (typeof encoding !== 'string' || encoding === '') encoding = 'utf8'

  // Assumption: byteLength() return value is always < kMaxLength.
  var length = byteLength(string, encoding) | 0
  that = allocate(that, length)

  that.write(string, encoding)
  return that
}

function fromObject (that, object) {
  if (Buffer.isBuffer(object)) return fromBuffer(that, object)

  if (isArray(object)) return fromArray(that, object)

  if (object == null) {
    throw new TypeError('must start with number, buffer, array or string')
  }

  if (typeof ArrayBuffer !== 'undefined') {
    if (object.buffer instanceof ArrayBuffer) {
      return fromTypedArray(that, object)
    }
    if (object instanceof ArrayBuffer) {
      return fromArrayBuffer(that, object)
    }
  }

  if (object.length) return fromArrayLike(that, object)

  return fromJsonObject(that, object)
}

function fromBuffer (that, buffer) {
  var length = checked(buffer.length) | 0
  that = allocate(that, length)
  buffer.copy(that, 0, 0, length)
  return that
}

function fromArray (that, array) {
  var length = checked(array.length) | 0
  that = allocate(that, length)
  for (var i = 0; i < length; i += 1) {
    that[i] = array[i] & 255
  }
  return that
}

// Duplicate of fromArray() to keep fromArray() monomorphic.
function fromTypedArray (that, array) {
  var length = checked(array.length) | 0
  that = allocate(that, length)
  // Truncating the elements is probably not what people expect from typed
  // arrays with BYTES_PER_ELEMENT > 1 but it's compatible with the behavior
  // of the old Buffer constructor.
  for (var i = 0; i < length; i += 1) {
    that[i] = array[i] & 255
  }
  return that
}

function fromArrayBuffer (that, array) {
  if (Buffer.TYPED_ARRAY_SUPPORT) {
    // Return an augmented `Uint8Array` instance, for best performance
    array.byteLength
    that = Buffer._augment(new Uint8Array(array))
  } else {
    // Fallback: Return an object instance of the Buffer class
    that = fromTypedArray(that, new Uint8Array(array))
  }
  return that
}

function fromArrayLike (that, array) {
  var length = checked(array.length) | 0
  that = allocate(that, length)
  for (var i = 0; i < length; i += 1) {
    that[i] = array[i] & 255
  }
  return that
}

// Deserialize { type: 'Buffer', data: [1,2,3,...] } into a Buffer object.
// Returns a zero-length buffer for inputs that don't conform to the spec.
function fromJsonObject (that, object) {
  var array
  var length = 0

  if (object.type === 'Buffer' && isArray(object.data)) {
    array = object.data
    length = checked(array.length) | 0
  }
  that = allocate(that, length)

  for (var i = 0; i < length; i += 1) {
    that[i] = array[i] & 255
  }
  return that
}

function allocate (that, length) {
  if (Buffer.TYPED_ARRAY_SUPPORT) {
    // Return an augmented `Uint8Array` instance, for best performance
    that = Buffer._augment(new Uint8Array(length))
  } else {
    // Fallback: Return an object instance of the Buffer class
    that.length = length
    that._isBuffer = true
  }

  var fromPool = length !== 0 && length <= Buffer.poolSize >>> 1
  if (fromPool) that.parent = rootParent

  return that
}

function checked (length) {
  // Note: cannot use `length < kMaxLength` here because that fails when
  // length is NaN (which is otherwise coerced to zero.)
  if (length >= kMaxLength()) {
    throw new RangeError('Attempt to allocate Buffer larger than maximum ' +
                         'size: 0x' + kMaxLength().toString(16) + ' bytes')
  }
  return length | 0
}

function SlowBuffer (subject, encoding) {
  if (!(this instanceof SlowBuffer)) return new SlowBuffer(subject, encoding)

  var buf = new Buffer(subject, encoding)
  delete buf.parent
  return buf
}

Buffer.isBuffer = function isBuffer (b) {
  return !!(b != null && b._isBuffer)
}

Buffer.compare = function compare (a, b) {
  if (!Buffer.isBuffer(a) || !Buffer.isBuffer(b)) {
    throw new TypeError('Arguments must be Buffers')
  }

  if (a === b) return 0

  var x = a.length
  var y = b.length

  var i = 0
  var len = Math.min(x, y)
  while (i < len) {
    if (a[i] !== b[i]) break

    ++i
  }

  if (i !== len) {
    x = a[i]
    y = b[i]
  }

  if (x < y) return -1
  if (y < x) return 1
  return 0
}

Buffer.isEncoding = function isEncoding (encoding) {
  switch (String(encoding).toLowerCase()) {
    case 'hex':
    case 'utf8':
    case 'utf-8':
    case 'ascii':
    case 'binary':
    case 'base64':
    case 'raw':
    case 'ucs2':
    case 'ucs-2':
    case 'utf16le':
    case 'utf-16le':
      return true
    default:
      return false
  }
}

Buffer.concat = function concat (list, length) {
  if (!isArray(list)) throw new TypeError('list argument must be an Array of Buffers.')

  if (list.length === 0) {
    return new Buffer(0)
  }

  var i
  if (length === undefined) {
    length = 0
    for (i = 0; i < list.length; i++) {
      length += list[i].length
    }
  }

  var buf = new Buffer(length)
  var pos = 0
  for (i = 0; i < list.length; i++) {
    var item = list[i]
    item.copy(buf, pos)
    pos += item.length
  }
  return buf
}

function byteLength (string, encoding) {
  if (typeof string !== 'string') string = '' + string

  var len = string.length
  if (len === 0) return 0

  // Use a for loop to avoid recursion
  var loweredCase = false
  for (;;) {
    switch (encoding) {
      case 'ascii':
      case 'binary':
      // Deprecated
      case 'raw':
      case 'raws':
        return len
      case 'utf8':
      case 'utf-8':
        return utf8ToBytes(string).length
      case 'ucs2':
      case 'ucs-2':
      case 'utf16le':
      case 'utf-16le':
        return len * 2
      case 'hex':
        return len >>> 1
      case 'base64':
        return base64ToBytes(string).length
      default:
        if (loweredCase) return utf8ToBytes(string).length // assume utf8
        encoding = ('' + encoding).toLowerCase()
        loweredCase = true
    }
  }
}
Buffer.byteLength = byteLength

// pre-set for values that may exist in the future
Buffer.prototype.length = undefined
Buffer.prototype.parent = undefined

function slowToString (encoding, start, end) {
  var loweredCase = false

  start = start | 0
  end = end === undefined || end === Infinity ? this.length : end | 0

  if (!encoding) encoding = 'utf8'
  if (start < 0) start = 0
  if (end > this.length) end = this.length
  if (end <= start) return ''

  while (true) {
    switch (encoding) {
      case 'hex':
        return hexSlice(this, start, end)

      case 'utf8':
      case 'utf-8':
        return utf8Slice(this, start, end)

      case 'ascii':
        return asciiSlice(this, start, end)

      case 'binary':
        return binarySlice(this, start, end)

      case 'base64':
        return base64Slice(this, start, end)

      case 'ucs2':
      case 'ucs-2':
      case 'utf16le':
      case 'utf-16le':
        return utf16leSlice(this, start, end)

      default:
        if (loweredCase) throw new TypeError('Unknown encoding: ' + encoding)
        encoding = (encoding + '').toLowerCase()
        loweredCase = true
    }
  }
}

Buffer.prototype.toString = function toString () {
  var length = this.length | 0
  if (length === 0) return ''
  if (arguments.length === 0) return utf8Slice(this, 0, length)
  return slowToString.apply(this, arguments)
}

Buffer.prototype.equals = function equals (b) {
  if (!Buffer.isBuffer(b)) throw new TypeError('Argument must be a Buffer')
  if (this === b) return true
  return Buffer.compare(this, b) === 0
}

Buffer.prototype.inspect = function inspect () {
  var str = ''
  var max = exports.INSPECT_MAX_BYTES
  if (this.length > 0) {
    str = this.toString('hex', 0, max).match(/.{2}/g).join(' ')
    if (this.length > max) str += ' ... '
  }
  return '<Buffer ' + str + '>'
}

Buffer.prototype.compare = function compare (b) {
  if (!Buffer.isBuffer(b)) throw new TypeError('Argument must be a Buffer')
  if (this === b) return 0
  return Buffer.compare(this, b)
}

Buffer.prototype.indexOf = function indexOf (val, byteOffset) {
  if (byteOffset > 0x7fffffff) byteOffset = 0x7fffffff
  else if (byteOffset < -0x80000000) byteOffset = -0x80000000
  byteOffset >>= 0

  if (this.length === 0) return -1
  if (byteOffset >= this.length) return -1

  // Negative offsets start from the end of the buffer
  if (byteOffset < 0) byteOffset = Math.max(this.length + byteOffset, 0)

  if (typeof val === 'string') {
    if (val.length === 0) return -1 // special case: looking for empty string always fails
    return String.prototype.indexOf.call(this, val, byteOffset)
  }
  if (Buffer.isBuffer(val)) {
    return arrayIndexOf(this, val, byteOffset)
  }
  if (typeof val === 'number') {
    if (Buffer.TYPED_ARRAY_SUPPORT && Uint8Array.prototype.indexOf === 'function') {
      return Uint8Array.prototype.indexOf.call(this, val, byteOffset)
    }
    return arrayIndexOf(this, [ val ], byteOffset)
  }

  function arrayIndexOf (arr, val, byteOffset) {
    var foundIndex = -1
    for (var i = 0; byteOffset + i < arr.length; i++) {
      if (arr[byteOffset + i] === val[foundIndex === -1 ? 0 : i - foundIndex]) {
        if (foundIndex === -1) foundIndex = i
        if (i - foundIndex + 1 === val.length) return byteOffset + foundIndex
      } else {
        foundIndex = -1
      }
    }
    return -1
  }

  throw new TypeError('val must be string, number or Buffer')
}

// `get` is deprecated
Buffer.prototype.get = function get (offset) {
  console.log('.get() is deprecated. Access using array indexes instead.')
  return this.readUInt8(offset)
}

// `set` is deprecated
Buffer.prototype.set = function set (v, offset) {
  console.log('.set() is deprecated. Access using array indexes instead.')
  return this.writeUInt8(v, offset)
}

function hexWrite (buf, string, offset, length) {
  offset = Number(offset) || 0
  var remaining = buf.length - offset
  if (!length) {
    length = remaining
  } else {
    length = Number(length)
    if (length > remaining) {
      length = remaining
    }
  }

  // must be an even number of digits
  var strLen = string.length
  if (strLen % 2 !== 0) throw new Error('Invalid hex string')

  if (length > strLen / 2) {
    length = strLen / 2
  }
  for (var i = 0; i < length; i++) {
    var parsed = parseInt(string.substr(i * 2, 2), 16)
    if (isNaN(parsed)) throw new Error('Invalid hex string')
    buf[offset + i] = parsed
  }
  return i
}

function utf8Write (buf, string, offset, length) {
  return blitBuffer(utf8ToBytes(string, buf.length - offset), buf, offset, length)
}

function asciiWrite (buf, string, offset, length) {
  return blitBuffer(asciiToBytes(string), buf, offset, length)
}

function binaryWrite (buf, string, offset, length) {
  return asciiWrite(buf, string, offset, length)
}

function base64Write (buf, string, offset, length) {
  return blitBuffer(base64ToBytes(string), buf, offset, length)
}

function ucs2Write (buf, string, offset, length) {
  return blitBuffer(utf16leToBytes(string, buf.length - offset), buf, offset, length)
}

Buffer.prototype.write = function write (string, offset, length, encoding) {
  // Buffer#write(string)
  if (offset === undefined) {
    encoding = 'utf8'
    length = this.length
    offset = 0
  // Buffer#write(string, encoding)
  } else if (length === undefined && typeof offset === 'string') {
    encoding = offset
    length = this.length
    offset = 0
  // Buffer#write(string, offset[, length][, encoding])
  } else if (isFinite(offset)) {
    offset = offset | 0
    if (isFinite(length)) {
      length = length | 0
      if (encoding === undefined) encoding = 'utf8'
    } else {
      encoding = length
      length = undefined
    }
  // legacy write(string, encoding, offset, length) - remove in v0.13
  } else {
    var swap = encoding
    encoding = offset
    offset = length | 0
    length = swap
  }

  var remaining = this.length - offset
  if (length === undefined || length > remaining) length = remaining

  if ((string.length > 0 && (length < 0 || offset < 0)) || offset > this.length) {
    throw new RangeError('attempt to write outside buffer bounds')
  }

  if (!encoding) encoding = 'utf8'

  var loweredCase = false
  for (;;) {
    switch (encoding) {
      case 'hex':
        return hexWrite(this, string, offset, length)

      case 'utf8':
      case 'utf-8':
        return utf8Write(this, string, offset, length)

      case 'ascii':
        return asciiWrite(this, string, offset, length)

      case 'binary':
        return binaryWrite(this, string, offset, length)

      case 'base64':
        // Warning: maxLength not taken into account in base64Write
        return base64Write(this, string, offset, length)

      case 'ucs2':
      case 'ucs-2':
      case 'utf16le':
      case 'utf-16le':
        return ucs2Write(this, string, offset, length)

      default:
        if (loweredCase) throw new TypeError('Unknown encoding: ' + encoding)
        encoding = ('' + encoding).toLowerCase()
        loweredCase = true
    }
  }
}

Buffer.prototype.toJSON = function toJSON () {
  return {
    type: 'Buffer',
    data: Array.prototype.slice.call(this._arr || this, 0)
  }
}

function base64Slice (buf, start, end) {
  if (start === 0 && end === buf.length) {
    return base64.fromByteArray(buf)
  } else {
    return base64.fromByteArray(buf.slice(start, end))
  }
}

function utf8Slice (buf, start, end) {
  end = Math.min(buf.length, end)
  var res = []

  var i = start
  while (i < end) {
    var firstByte = buf[i]
    var codePoint = null
    var bytesPerSequence = (firstByte > 0xEF) ? 4
      : (firstByte > 0xDF) ? 3
      : (firstByte > 0xBF) ? 2
      : 1

    if (i + bytesPerSequence <= end) {
      var secondByte, thirdByte, fourthByte, tempCodePoint

      switch (bytesPerSequence) {
        case 1:
          if (firstByte < 0x80) {
            codePoint = firstByte
          }
          break
        case 2:
          secondByte = buf[i + 1]
          if ((secondByte & 0xC0) === 0x80) {
            tempCodePoint = (firstByte & 0x1F) << 0x6 | (secondByte & 0x3F)
            if (tempCodePoint > 0x7F) {
              codePoint = tempCodePoint
            }
          }
          break
        case 3:
          secondByte = buf[i + 1]
          thirdByte = buf[i + 2]
          if ((secondByte & 0xC0) === 0x80 && (thirdByte & 0xC0) === 0x80) {
            tempCodePoint = (firstByte & 0xF) << 0xC | (secondByte & 0x3F) << 0x6 | (thirdByte & 0x3F)
            if (tempCodePoint > 0x7FF && (tempCodePoint < 0xD800 || tempCodePoint > 0xDFFF)) {
              codePoint = tempCodePoint
            }
          }
          break
        case 4:
          secondByte = buf[i + 1]
          thirdByte = buf[i + 2]
          fourthByte = buf[i + 3]
          if ((secondByte & 0xC0) === 0x80 && (thirdByte & 0xC0) === 0x80 && (fourthByte & 0xC0) === 0x80) {
            tempCodePoint = (firstByte & 0xF) << 0x12 | (secondByte & 0x3F) << 0xC | (thirdByte & 0x3F) << 0x6 | (fourthByte & 0x3F)
            if (tempCodePoint > 0xFFFF && tempCodePoint < 0x110000) {
              codePoint = tempCodePoint
            }
          }
      }
    }

    if (codePoint === null) {
      // we did not generate a valid codePoint so insert a
      // replacement char (U+FFFD) and advance only 1 byte
      codePoint = 0xFFFD
      bytesPerSequence = 1
    } else if (codePoint > 0xFFFF) {
      // encode to utf16 (surrogate pair dance)
      codePoint -= 0x10000
      res.push(codePoint >>> 10 & 0x3FF | 0xD800)
      codePoint = 0xDC00 | codePoint & 0x3FF
    }

    res.push(codePoint)
    i += bytesPerSequence
  }

  return decodeCodePointsArray(res)
}

// Based on http://stackoverflow.com/a/22747272/680742, the browser with
// the lowest limit is Chrome, with 0x10000 args.
// We go 1 magnitude less, for safety
var MAX_ARGUMENTS_LENGTH = 0x1000

function decodeCodePointsArray (codePoints) {
  var len = codePoints.length
  if (len <= MAX_ARGUMENTS_LENGTH) {
    return String.fromCharCode.apply(String, codePoints) // avoid extra slice()
  }

  // Decode in chunks to avoid "call stack size exceeded".
  var res = ''
  var i = 0
  while (i < len) {
    res += String.fromCharCode.apply(
      String,
      codePoints.slice(i, i += MAX_ARGUMENTS_LENGTH)
    )
  }
  return res
}

function asciiSlice (buf, start, end) {
  var ret = ''
  end = Math.min(buf.length, end)

  for (var i = start; i < end; i++) {
    ret += String.fromCharCode(buf[i] & 0x7F)
  }
  return ret
}

function binarySlice (buf, start, end) {
  var ret = ''
  end = Math.min(buf.length, end)

  for (var i = start; i < end; i++) {
    ret += String.fromCharCode(buf[i])
  }
  return ret
}

function hexSlice (buf, start, end) {
  var len = buf.length

  if (!start || start < 0) start = 0
  if (!end || end < 0 || end > len) end = len

  var out = ''
  for (var i = start; i < end; i++) {
    out += toHex(buf[i])
  }
  return out
}

function utf16leSlice (buf, start, end) {
  var bytes = buf.slice(start, end)
  var res = ''
  for (var i = 0; i < bytes.length; i += 2) {
    res += String.fromCharCode(bytes[i] + bytes[i + 1] * 256)
  }
  return res
}

Buffer.prototype.slice = function slice (start, end) {
  var len = this.length
  start = ~~start
  end = end === undefined ? len : ~~end

  if (start < 0) {
    start += len
    if (start < 0) start = 0
  } else if (start > len) {
    start = len
  }

  if (end < 0) {
    end += len
    if (end < 0) end = 0
  } else if (end > len) {
    end = len
  }

  if (end < start) end = start

  var newBuf
  if (Buffer.TYPED_ARRAY_SUPPORT) {
    newBuf = Buffer._augment(this.subarray(start, end))
  } else {
    var sliceLen = end - start
    newBuf = new Buffer(sliceLen, undefined)
    for (var i = 0; i < sliceLen; i++) {
      newBuf[i] = this[i + start]
    }
  }

  if (newBuf.length) newBuf.parent = this.parent || this

  return newBuf
}

/*
 * Need to make sure that buffer isn't trying to write out of bounds.
 */
function checkOffset (offset, ext, length) {
  if ((offset % 1) !== 0 || offset < 0) throw new RangeError('offset is not uint')
  if (offset + ext > length) throw new RangeError('Trying to access beyond buffer length')
}

Buffer.prototype.readUIntLE = function readUIntLE (offset, byteLength, noAssert) {
  offset = offset | 0
  byteLength = byteLength | 0
  if (!noAssert) checkOffset(offset, byteLength, this.length)

  var val = this[offset]
  var mul = 1
  var i = 0
  while (++i < byteLength && (mul *= 0x100)) {
    val += this[offset + i] * mul
  }

  return val
}

Buffer.prototype.readUIntBE = function readUIntBE (offset, byteLength, noAssert) {
  offset = offset | 0
  byteLength = byteLength | 0
  if (!noAssert) {
    checkOffset(offset, byteLength, this.length)
  }

  var val = this[offset + --byteLength]
  var mul = 1
  while (byteLength > 0 && (mul *= 0x100)) {
    val += this[offset + --byteLength] * mul
  }

  return val
}

Buffer.prototype.readUInt8 = function readUInt8 (offset, noAssert) {
  if (!noAssert) checkOffset(offset, 1, this.length)
  return this[offset]
}

Buffer.prototype.readUInt16LE = function readUInt16LE (offset, noAssert) {
  if (!noAssert) checkOffset(offset, 2, this.length)
  return this[offset] | (this[offset + 1] << 8)
}

Buffer.prototype.readUInt16BE = function readUInt16BE (offset, noAssert) {
  if (!noAssert) checkOffset(offset, 2, this.length)
  return (this[offset] << 8) | this[offset + 1]
}

Buffer.prototype.readUInt32LE = function readUInt32LE (offset, noAssert) {
  if (!noAssert) checkOffset(offset, 4, this.length)

  return ((this[offset]) |
      (this[offset + 1] << 8) |
      (this[offset + 2] << 16)) +
      (this[offset + 3] * 0x1000000)
}

Buffer.prototype.readUInt32BE = function readUInt32BE (offset, noAssert) {
  if (!noAssert) checkOffset(offset, 4, this.length)

  return (this[offset] * 0x1000000) +
    ((this[offset + 1] << 16) |
    (this[offset + 2] << 8) |
    this[offset + 3])
}

Buffer.prototype.readIntLE = function readIntLE (offset, byteLength, noAssert) {
  offset = offset | 0
  byteLength = byteLength | 0
  if (!noAssert) checkOffset(offset, byteLength, this.length)

  var val = this[offset]
  var mul = 1
  var i = 0
  while (++i < byteLength && (mul *= 0x100)) {
    val += this[offset + i] * mul
  }
  mul *= 0x80

  if (val >= mul) val -= Math.pow(2, 8 * byteLength)

  return val
}

Buffer.prototype.readIntBE = function readIntBE (offset, byteLength, noAssert) {
  offset = offset | 0
  byteLength = byteLength | 0
  if (!noAssert) checkOffset(offset, byteLength, this.length)

  var i = byteLength
  var mul = 1
  var val = this[offset + --i]
  while (i > 0 && (mul *= 0x100)) {
    val += this[offset + --i] * mul
  }
  mul *= 0x80

  if (val >= mul) val -= Math.pow(2, 8 * byteLength)

  return val
}

Buffer.prototype.readInt8 = function readInt8 (offset, noAssert) {
  if (!noAssert) checkOffset(offset, 1, this.length)
  if (!(this[offset] & 0x80)) return (this[offset])
  return ((0xff - this[offset] + 1) * -1)
}

Buffer.prototype.readInt16LE = function readInt16LE (offset, noAssert) {
  if (!noAssert) checkOffset(offset, 2, this.length)
  var val = this[offset] | (this[offset + 1] << 8)
  return (val & 0x8000) ? val | 0xFFFF0000 : val
}

Buffer.prototype.readInt16BE = function readInt16BE (offset, noAssert) {
  if (!noAssert) checkOffset(offset, 2, this.length)
  var val = this[offset + 1] | (this[offset] << 8)
  return (val & 0x8000) ? val | 0xFFFF0000 : val
}

Buffer.prototype.readInt32LE = function readInt32LE (offset, noAssert) {
  if (!noAssert) checkOffset(offset, 4, this.length)

  return (this[offset]) |
    (this[offset + 1] << 8) |
    (this[offset + 2] << 16) |
    (this[offset + 3] << 24)
}

Buffer.prototype.readInt32BE = function readInt32BE (offset, noAssert) {
  if (!noAssert) checkOffset(offset, 4, this.length)

  return (this[offset] << 24) |
    (this[offset + 1] << 16) |
    (this[offset + 2] << 8) |
    (this[offset + 3])
}

Buffer.prototype.readFloatLE = function readFloatLE (offset, noAssert) {
  if (!noAssert) checkOffset(offset, 4, this.length)
  return ieee754.read(this, offset, true, 23, 4)
}

Buffer.prototype.readFloatBE = function readFloatBE (offset, noAssert) {
  if (!noAssert) checkOffset(offset, 4, this.length)
  return ieee754.read(this, offset, false, 23, 4)
}

Buffer.prototype.readDoubleLE = function readDoubleLE (offset, noAssert) {
  if (!noAssert) checkOffset(offset, 8, this.length)
  return ieee754.read(this, offset, true, 52, 8)
}

Buffer.prototype.readDoubleBE = function readDoubleBE (offset, noAssert) {
  if (!noAssert) checkOffset(offset, 8, this.length)
  return ieee754.read(this, offset, false, 52, 8)
}

function checkInt (buf, value, offset, ext, max, min) {
  if (!Buffer.isBuffer(buf)) throw new TypeError('buffer must be a Buffer instance')
  if (value > max || value < min) throw new RangeError('value is out of bounds')
  if (offset + ext > buf.length) throw new RangeError('index out of range')
}

Buffer.prototype.writeUIntLE = function writeUIntLE (value, offset, byteLength, noAssert) {
  value = +value
  offset = offset | 0
  byteLength = byteLength | 0
  if (!noAssert) checkInt(this, value, offset, byteLength, Math.pow(2, 8 * byteLength), 0)

  var mul = 1
  var i = 0
  this[offset] = value & 0xFF
  while (++i < byteLength && (mul *= 0x100)) {
    this[offset + i] = (value / mul) & 0xFF
  }

  return offset + byteLength
}

Buffer.prototype.writeUIntBE = function writeUIntBE (value, offset, byteLength, noAssert) {
  value = +value
  offset = offset | 0
  byteLength = byteLength | 0
  if (!noAssert) checkInt(this, value, offset, byteLength, Math.pow(2, 8 * byteLength), 0)

  var i = byteLength - 1
  var mul = 1
  this[offset + i] = value & 0xFF
  while (--i >= 0 && (mul *= 0x100)) {
    this[offset + i] = (value / mul) & 0xFF
  }

  return offset + byteLength
}

Buffer.prototype.writeUInt8 = function writeUInt8 (value, offset, noAssert) {
  value = +value
  offset = offset | 0
  if (!noAssert) checkInt(this, value, offset, 1, 0xff, 0)
  if (!Buffer.TYPED_ARRAY_SUPPORT) value = Math.floor(value)
  this[offset] = value
  return offset + 1
}

function objectWriteUInt16 (buf, value, offset, littleEndian) {
  if (value < 0) value = 0xffff + value + 1
  for (var i = 0, j = Math.min(buf.length - offset, 2); i < j; i++) {
    buf[offset + i] = (value & (0xff << (8 * (littleEndian ? i : 1 - i)))) >>>
      (littleEndian ? i : 1 - i) * 8
  }
}

Buffer.prototype.writeUInt16LE = function writeUInt16LE (value, offset, noAssert) {
  value = +value
  offset = offset | 0
  if (!noAssert) checkInt(this, value, offset, 2, 0xffff, 0)
  if (Buffer.TYPED_ARRAY_SUPPORT) {
    this[offset] = value
    this[offset + 1] = (value >>> 8)
  } else {
    objectWriteUInt16(this, value, offset, true)
  }
  return offset + 2
}

Buffer.prototype.writeUInt16BE = function writeUInt16BE (value, offset, noAssert) {
  value = +value
  offset = offset | 0
  if (!noAssert) checkInt(this, value, offset, 2, 0xffff, 0)
  if (Buffer.TYPED_ARRAY_SUPPORT) {
    this[offset] = (value >>> 8)
    this[offset + 1] = value
  } else {
    objectWriteUInt16(this, value, offset, false)
  }
  return offset + 2
}

function objectWriteUInt32 (buf, value, offset, littleEndian) {
  if (value < 0) value = 0xffffffff + value + 1
  for (var i = 0, j = Math.min(buf.length - offset, 4); i < j; i++) {
    buf[offset + i] = (value >>> (littleEndian ? i : 3 - i) * 8) & 0xff
  }
}

Buffer.prototype.writeUInt32LE = function writeUInt32LE (value, offset, noAssert) {
  value = +value
  offset = offset | 0
  if (!noAssert) checkInt(this, value, offset, 4, 0xffffffff, 0)
  if (Buffer.TYPED_ARRAY_SUPPORT) {
    this[offset + 3] = (value >>> 24)
    this[offset + 2] = (value >>> 16)
    this[offset + 1] = (value >>> 8)
    this[offset] = value
  } else {
    objectWriteUInt32(this, value, offset, true)
  }
  return offset + 4
}

Buffer.prototype.writeUInt32BE = function writeUInt32BE (value, offset, noAssert) {
  value = +value
  offset = offset | 0
  if (!noAssert) checkInt(this, value, offset, 4, 0xffffffff, 0)
  if (Buffer.TYPED_ARRAY_SUPPORT) {
    this[offset] = (value >>> 24)
    this[offset + 1] = (value >>> 16)
    this[offset + 2] = (value >>> 8)
    this[offset + 3] = value
  } else {
    objectWriteUInt32(this, value, offset, false)
  }
  return offset + 4
}

Buffer.prototype.writeIntLE = function writeIntLE (value, offset, byteLength, noAssert) {
  value = +value
  offset = offset | 0
  if (!noAssert) {
    var limit = Math.pow(2, 8 * byteLength - 1)

    checkInt(this, value, offset, byteLength, limit - 1, -limit)
  }

  var i = 0
  var mul = 1
  var sub = value < 0 ? 1 : 0
  this[offset] = value & 0xFF
  while (++i < byteLength && (mul *= 0x100)) {
    this[offset + i] = ((value / mul) >> 0) - sub & 0xFF
  }

  return offset + byteLength
}

Buffer.prototype.writeIntBE = function writeIntBE (value, offset, byteLength, noAssert) {
  value = +value
  offset = offset | 0
  if (!noAssert) {
    var limit = Math.pow(2, 8 * byteLength - 1)

    checkInt(this, value, offset, byteLength, limit - 1, -limit)
  }

  var i = byteLength - 1
  var mul = 1
  var sub = value < 0 ? 1 : 0
  this[offset + i] = value & 0xFF
  while (--i >= 0 && (mul *= 0x100)) {
    this[offset + i] = ((value / mul) >> 0) - sub & 0xFF
  }

  return offset + byteLength
}

Buffer.prototype.writeInt8 = function writeInt8 (value, offset, noAssert) {
  value = +value
  offset = offset | 0
  if (!noAssert) checkInt(this, value, offset, 1, 0x7f, -0x80)
  if (!Buffer.TYPED_ARRAY_SUPPORT) value = Math.floor(value)
  if (value < 0) value = 0xff + value + 1
  this[offset] = value
  return offset + 1
}

Buffer.prototype.writeInt16LE = function writeInt16LE (value, offset, noAssert) {
  value = +value
  offset = offset | 0
  if (!noAssert) checkInt(this, value, offset, 2, 0x7fff, -0x8000)
  if (Buffer.TYPED_ARRAY_SUPPORT) {
    this[offset] = value
    this[offset + 1] = (value >>> 8)
  } else {
    objectWriteUInt16(this, value, offset, true)
  }
  return offset + 2
}

Buffer.prototype.writeInt16BE = function writeInt16BE (value, offset, noAssert) {
  value = +value
  offset = offset | 0
  if (!noAssert) checkInt(this, value, offset, 2, 0x7fff, -0x8000)
  if (Buffer.TYPED_ARRAY_SUPPORT) {
    this[offset] = (value >>> 8)
    this[offset + 1] = value
  } else {
    objectWriteUInt16(this, value, offset, false)
  }
  return offset + 2
}

Buffer.prototype.writeInt32LE = function writeInt32LE (value, offset, noAssert) {
  value = +value
  offset = offset | 0
  if (!noAssert) checkInt(this, value, offset, 4, 0x7fffffff, -0x80000000)
  if (Buffer.TYPED_ARRAY_SUPPORT) {
    this[offset] = value
    this[offset + 1] = (value >>> 8)
    this[offset + 2] = (value >>> 16)
    this[offset + 3] = (value >>> 24)
  } else {
    objectWriteUInt32(this, value, offset, true)
  }
  return offset + 4
}

Buffer.prototype.writeInt32BE = function writeInt32BE (value, offset, noAssert) {
  value = +value
  offset = offset | 0
  if (!noAssert) checkInt(this, value, offset, 4, 0x7fffffff, -0x80000000)
  if (value < 0) value = 0xffffffff + value + 1
  if (Buffer.TYPED_ARRAY_SUPPORT) {
    this[offset] = (value >>> 24)
    this[offset + 1] = (value >>> 16)
    this[offset + 2] = (value >>> 8)
    this[offset + 3] = value
  } else {
    objectWriteUInt32(this, value, offset, false)
  }
  return offset + 4
}

function checkIEEE754 (buf, value, offset, ext, max, min) {
  if (value > max || value < min) throw new RangeError('value is out of bounds')
  if (offset + ext > buf.length) throw new RangeError('index out of range')
  if (offset < 0) throw new RangeError('index out of range')
}

function writeFloat (buf, value, offset, littleEndian, noAssert) {
  if (!noAssert) {
    checkIEEE754(buf, value, offset, 4, 3.4028234663852886e+38, -3.4028234663852886e+38)
  }
  ieee754.write(buf, value, offset, littleEndian, 23, 4)
  return offset + 4
}

Buffer.prototype.writeFloatLE = function writeFloatLE (value, offset, noAssert) {
  return writeFloat(this, value, offset, true, noAssert)
}

Buffer.prototype.writeFloatBE = function writeFloatBE (value, offset, noAssert) {
  return writeFloat(this, value, offset, false, noAssert)
}

function writeDouble (buf, value, offset, littleEndian, noAssert) {
  if (!noAssert) {
    checkIEEE754(buf, value, offset, 8, 1.7976931348623157E+308, -1.7976931348623157E+308)
  }
  ieee754.write(buf, value, offset, littleEndian, 52, 8)
  return offset + 8
}

Buffer.prototype.writeDoubleLE = function writeDoubleLE (value, offset, noAssert) {
  return writeDouble(this, value, offset, true, noAssert)
}

Buffer.prototype.writeDoubleBE = function writeDoubleBE (value, offset, noAssert) {
  return writeDouble(this, value, offset, false, noAssert)
}

// copy(targetBuffer, targetStart=0, sourceStart=0, sourceEnd=buffer.length)
Buffer.prototype.copy = function copy (target, targetStart, start, end) {
  if (!start) start = 0
  if (!end && end !== 0) end = this.length
  if (targetStart >= target.length) targetStart = target.length
  if (!targetStart) targetStart = 0
  if (end > 0 && end < start) end = start

  // Copy 0 bytes; we're done
  if (end === start) return 0
  if (target.length === 0 || this.length === 0) return 0

  // Fatal error conditions
  if (targetStart < 0) {
    throw new RangeError('targetStart out of bounds')
  }
  if (start < 0 || start >= this.length) throw new RangeError('sourceStart out of bounds')
  if (end < 0) throw new RangeError('sourceEnd out of bounds')

  // Are we oob?
  if (end > this.length) end = this.length
  if (target.length - targetStart < end - start) {
    end = target.length - targetStart + start
  }

  var len = end - start
  var i

  if (this === target && start < targetStart && targetStart < end) {
    // descending copy from end
    for (i = len - 1; i >= 0; i--) {
      target[i + targetStart] = this[i + start]
    }
  } else if (len < 1000 || !Buffer.TYPED_ARRAY_SUPPORT) {
    // ascending copy from start
    for (i = 0; i < len; i++) {
      target[i + targetStart] = this[i + start]
    }
  } else {
    target._set(this.subarray(start, start + len), targetStart)
  }

  return len
}

// fill(value, start=0, end=buffer.length)
Buffer.prototype.fill = function fill (value, start, end) {
  if (!value) value = 0
  if (!start) start = 0
  if (!end) end = this.length

  if (end < start) throw new RangeError('end < start')

  // Fill 0 bytes; we're done
  if (end === start) return
  if (this.length === 0) return

  if (start < 0 || start >= this.length) throw new RangeError('start out of bounds')
  if (end < 0 || end > this.length) throw new RangeError('end out of bounds')

  var i
  if (typeof value === 'number') {
    for (i = start; i < end; i++) {
      this[i] = value
    }
  } else {
    var bytes = utf8ToBytes(value.toString())
    var len = bytes.length
    for (i = start; i < end; i++) {
      this[i] = bytes[i % len]
    }
  }

  return this
}

/**
 * Creates a new `ArrayBuffer` with the *copied* memory of the buffer instance.
 * Added in Node 0.12. Only available in browsers that support ArrayBuffer.
 */
Buffer.prototype.toArrayBuffer = function toArrayBuffer () {
  if (typeof Uint8Array !== 'undefined') {
    if (Buffer.TYPED_ARRAY_SUPPORT) {
      return (new Buffer(this)).buffer
    } else {
      var buf = new Uint8Array(this.length)
      for (var i = 0, len = buf.length; i < len; i += 1) {
        buf[i] = this[i]
      }
      return buf.buffer
    }
  } else {
    throw new TypeError('Buffer.toArrayBuffer not supported in this browser')
  }
}

// HELPER FUNCTIONS
// ================

var BP = Buffer.prototype

/**
 * Augment a Uint8Array *instance* (not the Uint8Array class!) with Buffer methods
 */
Buffer._augment = function _augment (arr) {
  arr.constructor = Buffer
  arr._isBuffer = true

  // save reference to original Uint8Array set method before overwriting
  arr._set = arr.set

  // deprecated
  arr.get = BP.get
  arr.set = BP.set

  arr.write = BP.write
  arr.toString = BP.toString
  arr.toLocaleString = BP.toString
  arr.toJSON = BP.toJSON
  arr.equals = BP.equals
  arr.compare = BP.compare
  arr.indexOf = BP.indexOf
  arr.copy = BP.copy
  arr.slice = BP.slice
  arr.readUIntLE = BP.readUIntLE
  arr.readUIntBE = BP.readUIntBE
  arr.readUInt8 = BP.readUInt8
  arr.readUInt16LE = BP.readUInt16LE
  arr.readUInt16BE = BP.readUInt16BE
  arr.readUInt32LE = BP.readUInt32LE
  arr.readUInt32BE = BP.readUInt32BE
  arr.readIntLE = BP.readIntLE
  arr.readIntBE = BP.readIntBE
  arr.readInt8 = BP.readInt8
  arr.readInt16LE = BP.readInt16LE
  arr.readInt16BE = BP.readInt16BE
  arr.readInt32LE = BP.readInt32LE
  arr.readInt32BE = BP.readInt32BE
  arr.readFloatLE = BP.readFloatLE
  arr.readFloatBE = BP.readFloatBE
  arr.readDoubleLE = BP.readDoubleLE
  arr.readDoubleBE = BP.readDoubleBE
  arr.writeUInt8 = BP.writeUInt8
  arr.writeUIntLE = BP.writeUIntLE
  arr.writeUIntBE = BP.writeUIntBE
  arr.writeUInt16LE = BP.writeUInt16LE
  arr.writeUInt16BE = BP.writeUInt16BE
  arr.writeUInt32LE = BP.writeUInt32LE
  arr.writeUInt32BE = BP.writeUInt32BE
  arr.writeIntLE = BP.writeIntLE
  arr.writeIntBE = BP.writeIntBE
  arr.writeInt8 = BP.writeInt8
  arr.writeInt16LE = BP.writeInt16LE
  arr.writeInt16BE = BP.writeInt16BE
  arr.writeInt32LE = BP.writeInt32LE
  arr.writeInt32BE = BP.writeInt32BE
  arr.writeFloatLE = BP.writeFloatLE
  arr.writeFloatBE = BP.writeFloatBE
  arr.writeDoubleLE = BP.writeDoubleLE
  arr.writeDoubleBE = BP.writeDoubleBE
  arr.fill = BP.fill
  arr.inspect = BP.inspect
  arr.toArrayBuffer = BP.toArrayBuffer

  return arr
}

var INVALID_BASE64_RE = /[^+\/0-9A-Za-z-_]/g

function base64clean (str) {
  // Node strips out invalid characters like \n and \t from the string, base64-js does not
  str = stringtrim(str).replace(INVALID_BASE64_RE, '')
  // Node converts strings with length < 2 to ''
  if (str.length < 2) return ''
  // Node allows for non-padded base64 strings (missing trailing ===), base64-js does not
  while (str.length % 4 !== 0) {
    str = str + '='
  }
  return str
}

function stringtrim (str) {
  if (str.trim) return str.trim()
  return str.replace(/^\s+|\s+$/g, '')
}

function toHex (n) {
  if (n < 16) return '0' + n.toString(16)
  return n.toString(16)
}

function utf8ToBytes (string, units) {
  units = units || Infinity
  var codePoint
  var length = string.length
  var leadSurrogate = null
  var bytes = []

  for (var i = 0; i < length; i++) {
    codePoint = string.charCodeAt(i)

    // is surrogate component
    if (codePoint > 0xD7FF && codePoint < 0xE000) {
      // last char was a lead
      if (!leadSurrogate) {
        // no lead yet
        if (codePoint > 0xDBFF) {
          // unexpected trail
          if ((units -= 3) > -1) bytes.push(0xEF, 0xBF, 0xBD)
          continue
        } else if (i + 1 === length) {
          // unpaired lead
          if ((units -= 3) > -1) bytes.push(0xEF, 0xBF, 0xBD)
          continue
        }

        // valid lead
        leadSurrogate = codePoint

        continue
      }

      // 2 leads in a row
      if (codePoint < 0xDC00) {
        if ((units -= 3) > -1) bytes.push(0xEF, 0xBF, 0xBD)
        leadSurrogate = codePoint
        continue
      }

      // valid surrogate pair
      codePoint = leadSurrogate - 0xD800 << 10 | codePoint - 0xDC00 | 0x10000
    } else if (leadSurrogate) {
      // valid bmp char, but last char was a lead
      if ((units -= 3) > -1) bytes.push(0xEF, 0xBF, 0xBD)
    }

    leadSurrogate = null

    // encode utf8
    if (codePoint < 0x80) {
      if ((units -= 1) < 0) break
      bytes.push(codePoint)
    } else if (codePoint < 0x800) {
      if ((units -= 2) < 0) break
      bytes.push(
        codePoint >> 0x6 | 0xC0,
        codePoint & 0x3F | 0x80
      )
    } else if (codePoint < 0x10000) {
      if ((units -= 3) < 0) break
      bytes.push(
        codePoint >> 0xC | 0xE0,
        codePoint >> 0x6 & 0x3F | 0x80,
        codePoint & 0x3F | 0x80
      )
    } else if (codePoint < 0x110000) {
      if ((units -= 4) < 0) break
      bytes.push(
        codePoint >> 0x12 | 0xF0,
        codePoint >> 0xC & 0x3F | 0x80,
        codePoint >> 0x6 & 0x3F | 0x80,
        codePoint & 0x3F | 0x80
      )
    } else {
      throw new Error('Invalid code point')
    }
  }

  return bytes
}

function asciiToBytes (str) {
  var byteArray = []
  for (var i = 0; i < str.length; i++) {
    // Node's code seems to be doing this and not & 0x7F..
    byteArray.push(str.charCodeAt(i) & 0xFF)
  }
  return byteArray
}

function utf16leToBytes (str, units) {
  var c, hi, lo
  var byteArray = []
  for (var i = 0; i < str.length; i++) {
    if ((units -= 2) < 0) break

    c = str.charCodeAt(i)
    hi = c >> 8
    lo = c % 256
    byteArray.push(lo)
    byteArray.push(hi)
  }

  return byteArray
}

function base64ToBytes (str) {
  return base64.toByteArray(base64clean(str))
}

function blitBuffer (src, dst, offset, length) {
  for (var i = 0; i < length; i++) {
    if ((i + offset >= dst.length) || (i >= src.length)) break
    dst[i + offset] = src[i]
  }
  return i
}

}).call(this,require('_process'),typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {},require("buffer").Buffer,arguments[3],arguments[4],arguments[5],arguments[6],"/node_modules/browserify/node_modules/buffer/index.js","/node_modules/browserify/node_modules/buffer")
},{"_process":28,"base64-js":25,"buffer":24,"ieee754":26,"is-array":27}],25:[function(require,module,exports){
(function (process,global,Buffer,__argument0,__argument1,__argument2,__argument3,__filename,__dirname){
var lookup = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

;(function (exports) {
	'use strict';

  var Arr = (typeof Uint8Array !== 'undefined')
    ? Uint8Array
    : Array

	var PLUS   = '+'.charCodeAt(0)
	var SLASH  = '/'.charCodeAt(0)
	var NUMBER = '0'.charCodeAt(0)
	var LOWER  = 'a'.charCodeAt(0)
	var UPPER  = 'A'.charCodeAt(0)
	var PLUS_URL_SAFE = '-'.charCodeAt(0)
	var SLASH_URL_SAFE = '_'.charCodeAt(0)

	function decode (elt) {
		var code = elt.charCodeAt(0)
		if (code === PLUS ||
		    code === PLUS_URL_SAFE)
			return 62 // '+'
		if (code === SLASH ||
		    code === SLASH_URL_SAFE)
			return 63 // '/'
		if (code < NUMBER)
			return -1 //no match
		if (code < NUMBER + 10)
			return code - NUMBER + 26 + 26
		if (code < UPPER + 26)
			return code - UPPER
		if (code < LOWER + 26)
			return code - LOWER + 26
	}

	function b64ToByteArray (b64) {
		var i, j, l, tmp, placeHolders, arr

		if (b64.length % 4 > 0) {
			throw new Error('Invalid string. Length must be a multiple of 4')
		}

		// the number of equal signs (place holders)
		// if there are two placeholders, than the two characters before it
		// represent one byte
		// if there is only one, then the three characters before it represent 2 bytes
		// this is just a cheap hack to not do indexOf twice
		var len = b64.length
		placeHolders = '=' === b64.charAt(len - 2) ? 2 : '=' === b64.charAt(len - 1) ? 1 : 0

		// base64 is 4/3 + up to two characters of the original data
		arr = new Arr(b64.length * 3 / 4 - placeHolders)

		// if there are placeholders, only get up to the last complete 4 chars
		l = placeHolders > 0 ? b64.length - 4 : b64.length

		var L = 0

		function push (v) {
			arr[L++] = v
		}

		for (i = 0, j = 0; i < l; i += 4, j += 3) {
			tmp = (decode(b64.charAt(i)) << 18) | (decode(b64.charAt(i + 1)) << 12) | (decode(b64.charAt(i + 2)) << 6) | decode(b64.charAt(i + 3))
			push((tmp & 0xFF0000) >> 16)
			push((tmp & 0xFF00) >> 8)
			push(tmp & 0xFF)
		}

		if (placeHolders === 2) {
			tmp = (decode(b64.charAt(i)) << 2) | (decode(b64.charAt(i + 1)) >> 4)
			push(tmp & 0xFF)
		} else if (placeHolders === 1) {
			tmp = (decode(b64.charAt(i)) << 10) | (decode(b64.charAt(i + 1)) << 4) | (decode(b64.charAt(i + 2)) >> 2)
			push((tmp >> 8) & 0xFF)
			push(tmp & 0xFF)
		}

		return arr
	}

	function uint8ToBase64 (uint8) {
		var i,
			extraBytes = uint8.length % 3, // if we have 1 byte left, pad 2 bytes
			output = "",
			temp, length

		function encode (num) {
			return lookup.charAt(num)
		}

		function tripletToBase64 (num) {
			return encode(num >> 18 & 0x3F) + encode(num >> 12 & 0x3F) + encode(num >> 6 & 0x3F) + encode(num & 0x3F)
		}

		// go through the array every three bytes, we'll deal with trailing stuff later
		for (i = 0, length = uint8.length - extraBytes; i < length; i += 3) {
			temp = (uint8[i] << 16) + (uint8[i + 1] << 8) + (uint8[i + 2])
			output += tripletToBase64(temp)
		}

		// pad the end with zeros, but make sure to not forget the extra bytes
		switch (extraBytes) {
			case 1:
				temp = uint8[uint8.length - 1]
				output += encode(temp >> 2)
				output += encode((temp << 4) & 0x3F)
				output += '=='
				break
			case 2:
				temp = (uint8[uint8.length - 2] << 8) + (uint8[uint8.length - 1])
				output += encode(temp >> 10)
				output += encode((temp >> 4) & 0x3F)
				output += encode((temp << 2) & 0x3F)
				output += '='
				break
		}

		return output
	}

	exports.toByteArray = b64ToByteArray
	exports.fromByteArray = uint8ToBase64
}(typeof exports === 'undefined' ? (this.base64js = {}) : exports))

}).call(this,require('_process'),typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {},require("buffer").Buffer,arguments[3],arguments[4],arguments[5],arguments[6],"/node_modules/browserify/node_modules/buffer/node_modules/base64-js/lib/b64.js","/node_modules/browserify/node_modules/buffer/node_modules/base64-js/lib")
},{"_process":28,"buffer":24}],26:[function(require,module,exports){
(function (process,global,Buffer,__argument0,__argument1,__argument2,__argument3,__filename,__dirname){
exports.read = function (buffer, offset, isLE, mLen, nBytes) {
  var e, m
  var eLen = nBytes * 8 - mLen - 1
  var eMax = (1 << eLen) - 1
  var eBias = eMax >> 1
  var nBits = -7
  var i = isLE ? (nBytes - 1) : 0
  var d = isLE ? -1 : 1
  var s = buffer[offset + i]

  i += d

  e = s & ((1 << (-nBits)) - 1)
  s >>= (-nBits)
  nBits += eLen
  for (; nBits > 0; e = e * 256 + buffer[offset + i], i += d, nBits -= 8) {}

  m = e & ((1 << (-nBits)) - 1)
  e >>= (-nBits)
  nBits += mLen
  for (; nBits > 0; m = m * 256 + buffer[offset + i], i += d, nBits -= 8) {}

  if (e === 0) {
    e = 1 - eBias
  } else if (e === eMax) {
    return m ? NaN : ((s ? -1 : 1) * Infinity)
  } else {
    m = m + Math.pow(2, mLen)
    e = e - eBias
  }
  return (s ? -1 : 1) * m * Math.pow(2, e - mLen)
}

exports.write = function (buffer, value, offset, isLE, mLen, nBytes) {
  var e, m, c
  var eLen = nBytes * 8 - mLen - 1
  var eMax = (1 << eLen) - 1
  var eBias = eMax >> 1
  var rt = (mLen === 23 ? Math.pow(2, -24) - Math.pow(2, -77) : 0)
  var i = isLE ? 0 : (nBytes - 1)
  var d = isLE ? 1 : -1
  var s = value < 0 || (value === 0 && 1 / value < 0) ? 1 : 0

  value = Math.abs(value)

  if (isNaN(value) || value === Infinity) {
    m = isNaN(value) ? 1 : 0
    e = eMax
  } else {
    e = Math.floor(Math.log(value) / Math.LN2)
    if (value * (c = Math.pow(2, -e)) < 1) {
      e--
      c *= 2
    }
    if (e + eBias >= 1) {
      value += rt / c
    } else {
      value += rt * Math.pow(2, 1 - eBias)
    }
    if (value * c >= 2) {
      e++
      c /= 2
    }

    if (e + eBias >= eMax) {
      m = 0
      e = eMax
    } else if (e + eBias >= 1) {
      m = (value * c - 1) * Math.pow(2, mLen)
      e = e + eBias
    } else {
      m = value * Math.pow(2, eBias - 1) * Math.pow(2, mLen)
      e = 0
    }
  }

  for (; mLen >= 8; buffer[offset + i] = m & 0xff, i += d, m /= 256, mLen -= 8) {}

  e = (e << mLen) | m
  eLen += mLen
  for (; eLen > 0; buffer[offset + i] = e & 0xff, i += d, e /= 256, eLen -= 8) {}

  buffer[offset + i - d] |= s * 128
}

}).call(this,require('_process'),typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {},require("buffer").Buffer,arguments[3],arguments[4],arguments[5],arguments[6],"/node_modules/browserify/node_modules/buffer/node_modules/ieee754/index.js","/node_modules/browserify/node_modules/buffer/node_modules/ieee754")
},{"_process":28,"buffer":24}],27:[function(require,module,exports){
(function (process,global,Buffer,__argument0,__argument1,__argument2,__argument3,__filename,__dirname){

/**
 * isArray
 */

var isArray = Array.isArray;

/**
 * toString
 */

var str = Object.prototype.toString;

/**
 * Whether or not the given `val`
 * is an array.
 *
 * example:
 *
 *        isArray([]);
 *        // > true
 *        isArray(arguments);
 *        // > false
 *        isArray('');
 *        // > false
 *
 * @param {mixed} val
 * @return {bool}
 */

module.exports = isArray || function (val) {
  return !! val && '[object Array]' == str.call(val);
};

}).call(this,require('_process'),typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {},require("buffer").Buffer,arguments[3],arguments[4],arguments[5],arguments[6],"/node_modules/browserify/node_modules/buffer/node_modules/is-array/index.js","/node_modules/browserify/node_modules/buffer/node_modules/is-array")
},{"_process":28,"buffer":24}],28:[function(require,module,exports){
(function (process,global,Buffer,__argument0,__argument1,__argument2,__argument3,__filename,__dirname){
// shim for using process in browser

var process = module.exports = {};
var queue = [];
var draining = false;

function drainQueue() {
    if (draining) {
        return;
    }
    draining = true;
    var currentQueue;
    var len = queue.length;
    while(len) {
        currentQueue = queue;
        queue = [];
        var i = -1;
        while (++i < len) {
            currentQueue[i]();
        }
        len = queue.length;
    }
    draining = false;
}
process.nextTick = function (fun) {
    queue.push(fun);
    if (!draining) {
        setTimeout(drainQueue, 0);
    }
};

process.title = 'browser';
process.browser = true;
process.env = {};
process.argv = [];
process.version = ''; // empty string to avoid regexp issues
process.versions = {};

function noop() {}

process.on = noop;
process.addListener = noop;
process.once = noop;
process.off = noop;
process.removeListener = noop;
process.removeAllListeners = noop;
process.emit = noop;

process.binding = function (name) {
    throw new Error('process.binding is not supported');
};

// TODO(shtylman)
process.cwd = function () { return '/' };
process.chdir = function (dir) {
    throw new Error('process.chdir is not supported');
};
process.umask = function() { return 0; };

}).call(this,require('_process'),typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {},require("buffer").Buffer,arguments[3],arguments[4],arguments[5],arguments[6],"/node_modules/browserify/node_modules/process/browser.js","/node_modules/browserify/node_modules/process")
},{"_process":28,"buffer":24}],"common_api":[function(require,module,exports){
(function (process,global,Buffer,__argument0,__argument1,__argument2,__argument3,__filename,__dirname){
// var _ = require('lodash');
var Api = {
  ENDPOINTS: {
    users: '/users',
    fetch_user_details: '/users/{{uuid}}',
    user_export: '/user/export',
    activate_user: '/users/UUID/active',
    reinvite_user: '/users/resend_invite',
    upload_user_csv: '/user/import',
    calendar_user_availability: '/calendar/users',
    event_info: '/event_info',
    event_configurations: '/event/{event_uuid}/configurations',
    user_make_available: '/calendar/make_available',
    user_make_unavailable: '/calendar/make_unavailable',
    user_block: '/calendar/block',
    user_unblock: '/calendar/unblock',
    block_update: '/calendar/edit_block',
    user_calendar_export: '/calendar/users/export',
    company_fetch: '/company',
    register_user: '/register',
    alert_fetch: '/alerts',
    alert_details_fetch: '/alerts/meeting_meta',
    dismiss_alert: '/alerts/dismiss',
    dismiss_alert: '/alerts/dismiss',
    notification_fetch: '/notifications',
    dismiss_notification: '/notifications/dismiss',
    update_user_profile: '/user/{{uuid}}',
    fetch_meetings_analytics: '/analytics/meetings',
    fetch_invitees_analytics: '/analytics/invitees',
    fetch_customers_analytics: '/analytics/customers',
    fetch_roles_analytics: '/analytics/roles',
    users_events: '/users_events',
    reinvite_users: "/users/resend_invite",
    remove_from_event: '/users/UUID/inactive',
    users_events_filters: '/users_events_filters',
    meeting_request_path: '/meeting_request/new',
    meeting_request_view_path: '/meeting_request/{uuid}/view',
    meeting_request_export: '/meeting_request/export',
    roles_fetch: '/roles',
    role_create: '/role/create',
    role_update: '/role/update',
    role_get_privileges: '/role/{:uuid}/get_privileges',
    role_set_privileges: '/role/{:uuid}/set_privileges',
    role_enable: '/role/{:uuid}/enable',
    role_disable: '/role/{:uuid}/disable',
    meeting_get_config: '/configure/{:uuid}/meeting_type',
    meeting_set_config: '/configure/{:uuid}/meeting_type_update',
    meeting_set_setting: '/setting/activity_update',
    meeting_get_settings: '/setting/activity',
    meeting_types: '/meeting_types',
    ui_set_setting: '/setting/ui_update',
    ui_get_settings: '/setting/ui',
    get_announcements: '/setting/announcement',
    set_announcements: '/setting/announcement_update',
    availability_fetch: '/configure/initial_availabilities',
    availability_update: '/configure/update_initial_availabilities',
    all_meeting_types: '/meeting_types/index',
    event_info: '/events',
    rooms_list: '/rooms/list',
    rooms_export: '/room/export',
    room_create: '/room/create',
    room_update: '/room/update',
    meetings_list: '/meeting_requests',
    facilities_list: '/facilities',
    meeting_availability: '/meeting_request/calendar',
    availability_fetch: '/configure/initial_availabilities',
    internal_attendees: '/users/internal',
    external_attendees: '/users/external',
    availability_fetch: '/configure/initial_availabilities',
    availability_update: '/configure/update_initial_availabilities',
    calendar_availability: '/meeting_request/calendar',
    meeting_create: '/meeting_request/create',
    meeting_fetch: '/meeting_request/{{uuid}}/show',
    user_create: '/user/create',
    user_update: '/users/{{uuid}}/update',
    update_mail_template: '/mail_template/update',
    mail_template_type_get: '/mail_actions',
    mail_template_type_entities_get: '/mail_action/get_associated_entities',
    accept_meeting: '/meeting_request/{uuid}/accept_meeting',
    decline_meeting: '/meeting_request/{uuid}/decline_meeting',
    reschedule_meeting: '/meeting_request/reschedule',
    events_info: '/events',
    event_config: '/event/configurations',
    room_availability: '/calendar/rooms',
    room_calendar_export: '/calendar/rooms/export',
    room_block: '/calendar/block',
    room_unblock: '/calendar/unblock',
    room_make_available: '/calendar/make_available',
    room_make_unavailable: '/calendar/make_unavailable',
    block_update: '/calendar/edit_block',
    meeting_drag: '/calendar/relocate',
    meeting_request_path: '/meeting_request/new',
    meeting_request_edit_path: '/meeting_request/{uuid}/edit',
    upload_room_csv: '/room/import',
    save_form: '/custom_form/update',
    fetch_form: '/custom_form/get_fields',
    alert_fetch: '/alerts',
    alert_details_fetch: '/alerts/meeting_meta',
    dismiss_alert: '/alerts/dismiss',
    dismiss_alert: '/alerts/dismiss',
    notification_fetch: '/notifications',
    dismiss_notification: '/notifications/dismiss',
    fetch_meetings_analytics: '/analytics/meetings',
    fetch_invitees_analytics: '/analytics/invitees',
    fetch_customers_analytics: '/analytics/customers',
    fetch_roles_analytics: '/analytics/roles',
    fetch_rooms_analytics: '/analytics/rooms',
    fetch_booking_analytics: '/analytics/booking',
    fetch_meeting_filters: '/reports/meeting_filters',
    fetch_meeting_data_for_reports: '/users/meetings',
    standard_report_export_url: '/users/meetings.pdf?user_uuid={{uuid}}',
    fetch_users_for_reports: '/reports/users_list',
    fetch_meeting_reports: '/meetings',
    fetch_meeting_reports_header: '/headers',
    activate_event: '/event/activate',
    fetch_activity_list: '/activities',
    cancel_meeting: '/meeting_request/{meeting_uuid}/cancel_meeting',
    time_zone_url: '/time_zone',
    fetch_minimum_timeslot: '/setting/minimum_timeslot',
    update_minimum_timeslot: '/setting/minimum_timeslot_update',
    demand_report_export: '/meeting_request/ondemand',
    mapped_events: '/mappable_events',
    get_nav_header: '/events_meetings_menu',
    fetch_account: '/fetch_account',
    fetch_opportunity: '/fetch_opportunity',
    fetch_meeting_info: '/meeting_request/new.json',
    fetch_edit_meeting_info: '/meeting_request/{UUID}/edit.json',
    room_activities: '/activities_rooms',
    event_env_details: '/event_info'
  },

  update: function(options) {
    var options = _.assign({
      dataType: 'json',
      type: 'post',
      url: '/events',
      // global: true,
      prefix: 'test',
      data: {event: null}
    }, options);

    if(/^https?/.test(options['url'])) {
        $("#cover").fadeIn();
        return this.makePostCall(options['url']);
    }
    else if(options['url'] === this.ENDPOINTS.meeting_create || options['url'] === this.ENDPOINTS.reschedule_meeting){
        var data = {api_params: options.data};
        var meetingRequest = options.data.meeting_request;
        return this.createMeetingByFS(meetingRequest.account_id, meetingRequest.opportunity_id, JSON.stringify(data));
    }
  },

  fetch: function(options) {

    var options = _.assign({
      dataType: 'json',
      type: 'get',
      // global: true,
      prefix: 'test',
      url: '/events',
      trimSearch: true
    }, options);

    $("#cover").fadeIn();
    
    if(options['url'] === this.ENDPOINTS.users_events) {
        return this.eventsFromSF();
    } 
    else if(options['url'] === this.ENDPOINTS.get_nav_header) {
        return this.navHeaderFromSF();
    } 
    else if(options['url'] === this.ENDPOINTS.meetings_list){
        var data = {api_params: options.data};
        return this.meetingFromSF($.param(data));
    }
    else if(options['url'] === this.ENDPOINTS.event_env_details){
        return this.meetingListCallsFS(options.url);
    }
    else if(options['url'] === this.ENDPOINTS.fetch_account){
        return this.accountFromSF(options.data);
    }
    else if(options['url'] === this.ENDPOINTS.fetch_opportunity){
        return this.opportunityFromSF(options.data);
    }
    else if(options['url'] === this.ENDPOINTS.fetch_meeting_info || options['url'] === this.ENDPOINTS.fetch_edit_meeting_info){
        var url = options.url.replace("{UUID}", $.urlParam('meeting'));
        return this.bookMeetingCallsFS(url, options.data);
    }
    else if(options['url'] === this.ENDPOINTS.external_attendees){
        //options['data']['accountID'] = $.urlParam('accid');
        return this.fetchExternalAttendeeformSF(options['data']);
    }
    else if(options['url'] === this.ENDPOINTS.calendar_availability){
        var data = {api_params: options.data};
        return this.fetchUpdatedCalendarFromFS($.param(data));
    }
    else if(options['url'] === this.ENDPOINTS.fetch_form || options['url'] === this.ENDPOINTS.room_activities || options['url'] === this.ENDPOINTS.internal_attendees || options['url'] === this.ENDPOINTS.event_info || options['url'] === this.ENDPOINTS.availability_fetch){
        return this.bookMeetingCallsFS(options.url, options.data);
    }
    else if(options.url.includes('/cancel_meeting')){
        return this.bookMeetingCallsFS(options.url, options.data);
    }
  },

  createMeetingByFS: function(accountID, opptyID, request){
    var promise = new Promise(function(resolve, reject){
        var accountID = accountID || "";
        var opptyID = opptyID || "";
        jiffle.JNBookMeeting.createMeeting($.urlParam('eventName'), accountID, opptyID, request, function(result, event) {
            $("#cover").fadeOut();
            var response = (typeof result == "string") ? this.unescapeJSON(result) : result;
            if(event.statusCode === 200) {
                if(response.status === 200){
                    resolve(response);
                }
                else {
                    reject(response);
                }
            } else {
                reject(response);
            }
        }.bind(this));
    }.bind(this));
    return promise;
  },

  fetchUpdatedCalendarFromFS: function(queryStr){
    var promise = new Promise(function(resolve, reject){
        jiffle.JNBookMeeting.getCalendar($.urlParam('eventName'), queryStr, function(result, event) {
            $("#cover").fadeOut();
            if(event.statusCode === 200) {
                var response = (typeof result == "string") ? this.unescapeJSON(result) : result;
                resolve(response);
            } else {
                reject("Error");
            }
        }.bind(this));
    }.bind(this));
    return promise;
  },

  fetchExternalAttendeeformSF: function(optionData){
    var promise = new Promise(function(resolve, reject){
        var accountID = accountName = "";
        if(meetingInfo.request.mode !== 'edit'){
            accountID = $.urlParam('accid');
        }
        if(optionData.account_id){
            accountID = optionData.account_id;
        }
        if(optionData.account_name){
            accountName = optionData.account_name || "";
        }
        jiffle.JNBookMeeting.getExtAtt(accountID, accountName, optionData.per_page, optionData.page, function(result, event) {
            $("#cover").fadeOut();
            if(event.statusCode === 200) {
                if(meetingInfo.account_id !== accountID){
                    meetingInfo.externalAttendees = {};
                    meetingInfo.account_id = accountID;
                }
                var response = (typeof result == "string") ? this.unescapeJSON(result) : result;
                _.forEach(response.data.items, function(item, index){
                    if(!meetingInfo.externalAttendees[item.email]){
                        item['uuid'] = "dummy_" + Math.random().toString(36).substring(2);
                        item['statuses'] =  { verified: false, active: true, approved: null, sso_enabled: false };
                        meetingInfo.externalAttendees[item.email] = item; //_.cloneDeep(item);
                    }
                    else {
                        response.data.items[index] = meetingInfo.externalAttendees[item.email];
                    }
                    
                });
                resolve(response);
            } else {
                reject("Error");
            }
        }.bind(this));
    }.bind(this));
    return promise;
  },

  bookMeetingCallsFS: function(url, data){
    var promise = new Promise(function(resolve, reject){
        var queryStr = "";
        if(data !== undefined && !$.isEmptyObject(data)){
            queryStr = $.param({api_params: data});
        }
        jiffle.JNBookMeeting.callJNMethod($.urlParam('eventName'), url, queryStr, function(result, event) {
            $("#cover").fadeOut();
            if(event.statusCode === 200) {
                var response = (typeof result == "string") ? this.unescapeJSON(result) : result;
                resolve(response);
            } else {
                reject("Error");
            }
        }.bind(this));
    }.bind(this));
    return promise;
  },

  accountFromSF: function(options) {
    var promise = new Promise(function(resolve, reject){
        jiffle.JNBookMeeting.searchAccOpty(options.name, options.id, function(result, event) {
            $("#cover").fadeOut();
            if(event.statusCode === 200) {
                var response = {};
                if((typeof result == "string")){
                    response = JSON.parse(unescape(JSON.stringify(this.unescapeJSON(result))).replace(/\+/g, " "));
                }
                else {
                    response = JSON.parse(unescape(JSON.stringify(result)).replace(/\+/g, " "));    
                }
                console.log("Resolved:",response);
                resolve(response);
            } else {
                reject("Error");
            }
        }.bind(this));
    }.bind(this));
    return promise;
  },

  opportunityFromSF: function(options) {
    var promise = new Promise(function(resolve, reject){
        jiffle.JNBookMeeting.getOptyList(options.name, options.id, function(result, event) {
            $("#cover").fadeOut();
            if(event.statusCode === 200) {
                var response = {};
                if((typeof result == "string")){
                    response = JSON.parse(unescape(JSON.stringify(this.unescapeJSON(result))).replace(/\+/g, " "));
                }
                else {
                    response = JSON.parse(unescape(JSON.stringify(result)).replace(/\+/g, " "));    
                }
                console.log("Resolved:",response);
                resolve(response);
            } else {
                reject("Error");
            }
        }.bind(this));
    }.bind(this));
    return promise;
  },

  navHeaderFromSF: function() {
    var promise = new Promise(function(resolve, reject){
        var params = {
            aID: $.urlParam('accid'),
            oID: $.urlParam('oppid'),
            aName: decodeURIComponent($.urlParam('accname')).replace(/\+/g, ' '),
            oName: decodeURIComponent($.urlParam('oppname')).replace(/\+/g, ' ')
        };
        jiffle.JNBookMeeting.getMenuList(params.aID, params.aName, params.oID, params.oName, function(result, event) {
            $("#cover").fadeOut();
            if(event.statusCode === 200) {
                var response = (typeof result == "string") ? this.unescapeJSON(result) : result;
                _.forEach(response.data.links, function(link){
                    link.url = unescape(link.url);
                });
                console.log("Resolved:",response);
                resolve(response);
            } else {
                reject("Error");
            }
        }.bind(this));
    }.bind(this));
    return promise;
  },

  eventsFromSF: function() {
    var promise = new Promise(function(resolve, reject){
        var params = {
            aID: $.urlParam('accid'),
            oID: $.urlParam('oppid'),
            aName: decodeURIComponent($.urlParam('accname')).replace(/\+/g, ' '),
            oName: decodeURIComponent($.urlParam('oppname')).replace(/\+/g, ' ')
        };
        jiffle.JNEventMeetingList.getEventList(params.aID, params.aName, params.oID, params.oName, function(result, event) {
            $("#cover").fadeOut();
            if(event.statusCode === 200) {
                _.forEach(result.data.events, function(oneEvent){
                    oneEvent.event_url = unescape(oneEvent.event_url);
                    oneEvent.action.url = unescape(oneEvent.action.url);
                });
                resolve(result);
            } else {
                reject("Error");
            }
        })
    });
    return promise;
  },

  meetingFromSF: function(queryStr) {
    var eventName = window.location.href.match(new RegExp('[\?&]eventName=([^&#]*)'))[1];
    var promise = new Promise(function(resolve, reject){
      jiffle.JNEventMeetingList.getMeetingListdb(eventName, queryStr, function(result, event) {
        $("#cover").fadeOut();
        if(event.statusCode === 200) {
          var response = (typeof result == "string") ? this.unescapeJSON(result) : result;
          console.log("Resolved:",response);
          resolve(response);
        } else {
          console.log("error:",result);
          reject("Error");
        }
      }.bind(this));
    }.bind(this));
    return promise;
  },

  meetingListCallsFS: function(url){
    var promise = new Promise(function(resolve, reject){
        jiffle.JNEventMeetingList.callJNMethod($.urlParam('eventName'), url, "", function(result, event) {
            $("#cover").fadeOut();
            if(event.statusCode === 200) {
                var response = (typeof result == "string") ? this.unescapeJSON(result) : result;
                resolve(response);
            } else {
                reject("Error");
            }
        }.bind(this));
    }.bind(this));
    return promise;
  },

  makePostCall: function(url) {
    var promise = new Promise(function(resolve, reject){
        jiffle.JNEventMeetingList.doJNPost(url, function(result, event) {
            $("#cover").fadeOut();
            if(event.statusCode === 200) {
                var response = (typeof result == "string") ? this.unescapeJSON(result) : result;
                console.log("Resolved:",response);
                resolve(response);
            } else {
                console.log("Error:",result);
                reject("Error");
            }
        }.bind(this));
    }.bind(this));
    return promise;
  },

  unescapeJSON: function(result) {
    var result = result.replace(/&amp;/g, '&')
                .replace(/&lt;/g, '<')
                .replace(/&gt;/g, '>')
                .replace(/&quot;/g, '"')
                .replace(/&#039;/g, "'");

    return JSON.parse(result);
  }

};

if(typeof jiffle === 'undefined'){
  // It doesn't, so create an object with that name
  window["jiffle"] = {};
  jiffle.JNBookMeeting = JNBookMeeting;
  //jiffle.JNEventMeetingList = JNEventMeetingList;
}

mode = 'new';
meetingInfo = {
    account_id: "",
    externalAttendees: {},
    requestors: [],
    selectedRequestor: "",
    domain_validate_url: "",
    request: { mode : "new", meeting_with: "", custom_fields: {}, showCancel: false }
};
envDetails = {
    companyName: "",
    currentManagedUser: "",
    currentUser: { first_name: "", last_name: "" },
    isExecutiveAdmin: function(){ return false; }
};

$(document).ready(function(){
    $("#cover").fadeIn();
    $(window).on('load', function(){
        window.setTimeout(function(){
            $("#cover").fadeOut();
        }, 3000);
    });

    $.urlParam = function(name){
        var results = new RegExp('[\?&]' + name + '=([^&#]*)').exec(window.location.href);
        if (results==null){
           return "";
        }
        else{
           return results[1] || 0;
        }
    }

    var promise = Api.fetch({
        url: Api.ENDPOINTS.get_nav_header
    });
    promise.then(function(response){
        var html = HandlebarsTemplates['sfdc/nav-header']({ headerLinks: response.data.links });
        $("#sf-jiffle-now").prepend(html);
    });
    
    /*var promise = Api.fetch({
        url: Api.ENDPOINTS.fetch_meeting_info
    });
    promise.then(function(data){
        meetingInfo.requestors = data.requestors;
        meetingInfo.selected_requestor = data.selected_requestor;
        meetingInfo.domain_validate_url = data.domain_validate_url;
        envDetails.currentManagedUser = data.current_managed_user;
        envDetails.currentUser = data.current_user;
        envDetails.companyName = data.companyname;
    });*/
    
});

module.exports = Api;



}).call(this,require('_process'),typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {},require("buffer").Buffer,arguments[3],arguments[4],arguments[5],arguments[6],"/app/scripts/commons/sfdc/api.js","/app/scripts/commons/sfdc")
},{"_process":28,"buffer":24}]},{},[1]);
