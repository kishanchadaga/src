require=(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
(function (process,global,Buffer,__argument0,__argument1,__argument2,__argument3,__filename,__dirname){
initI18n(enLocale["meetings"]);
var Handler = require('./handler');
var Api = require('common_api');

Handlebars.registerHelper("add", function() {
  var total = _.sum(arguments);
  return new Handlebars.SafeString(total);
});

$(document).ready(function(){
	var promise = Api.fetch({
        url: Api.ENDPOINTS.event_env_details
    });
    promise.then(function(response){
        window.envDetails = {};
    	envDetails.event = response.data.event;
        envDetails.currentUser = response.data.current_user;
        Handler.init();
    });
	
    setupUiI18n();
});



}).call(this,require('_process'),typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {},require("buffer").Buffer,arguments[3],arguments[4],arguments[5],arguments[6],"/app/scripts/Meeting/app.js","/app/scripts/Meeting")
},{"./handler":3,"_process":9,"buffer":5,"common_api":"common_api"}],2:[function(require,module,exports){
(function (process,global,Buffer,__argument0,__argument1,__argument2,__argument3,__filename,__dirname){
var MeetingActions = Reflux.createActions([
    'fetchMeetings',
    'searchMeetings',
    'updateSearch',
    'resetFilter',
    'updateFilter',
    'updateTimeFilter',
    'updateStageFilter',
    'updateAppliedFilters',
    'applyFilter',
    'acceptMeeting',
    'toggleView'
]);

module.exports = MeetingActions;



}).call(this,require('_process'),typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {},require("buffer").Buffer,arguments[3],arguments[4],arguments[5],arguments[6],"/app/scripts/Meeting/actions.js","/app/scripts/Meeting")
},{"_process":9,"buffer":5}],3:[function(require,module,exports){
(function (process,global,Buffer,__argument0,__argument1,__argument2,__argument3,__filename,__dirname){
var Actions = require('./actions');
var Store = require('./store');
// var _ = require('lodash');
// var i18n = require('i18next-client');

var MeetingHandler = (function () {

    var meetingListContainer = $('#meeting_list');
    var appliedFiltersContainer = $('#applied_filters_list')
    var toggleBtnUl = $(".toggle-menu-list");
    var globalFilter = $('#global_filter');
    var filterSearchField = $('#filter_search');
    var resetFilterBtn = $('#reset_filter')
    var applyFilterBtn = $('#apply_filter');
    var filterToggleBtn = $('#filter_toggle');
    var filter = $('#filter');
    var filterStartDate = $('#filter_start_date');
    var filterEndDate = $('#filter_end_date');
    var exportBtn = $('#export');
    var meetingCount = $('.meeting_count');
    var meetingItem = $(".meeting-card");
    var meetingAcceptBtn = $(".meeting-accept");
    var meetingDeclineBtn = $(".meeting-decline");
    var bookMeetingBtn = $("#book-meeting");

    var storeHandlers = {
      meetinglisting: handelMeetingList,
      viewchanged: handelViewToggle
    };

    function init() {
      Store.MeetingStore.listen(function(data){
        var func = storeHandlers[data.type];
        if(func) {
            func(data.data);
        }
      });

      Store.MeetingAcceptDeclineStore.listen(function(result){
        updateMeetingState(result);
      });

      setupUI();
      setupListeners();

      exportBtn.on('click', exportMeetings);
    };

    function setupUI () {
      Actions.fetchMeetings(1);
      var startDate = moment(envDetails.event.start_date, "YYYY-MM-DD");
      var endDate = moment(envDetails.event.end_date, "YYYY-MM-DD");
      filterStartDate.datepicker({
        dateFormat: "mm/dd/yy",
        minDate: startDate._d,
        maxDate: endDate._d
      });
      filterEndDate.datepicker({
        dateFormat: "mm/dd/yy",
        minDate: startDate._d,
        maxDate: endDate._d
      });
    };

    function updateToggleViewState(e){
      e.preventDefault();
      var El = $(e.currentTarget);
      if(!El.hasClass("active")){
        Actions.toggleView(El.data("switch-type"));
      }
    };

    function handelViewToggle(data){
      var viewStyle = data.viewStyle;
      var listHolder = meetingListContainer.find('.meeting-list');
      toggleBtnUl.find("a").toggleClass("active");
      listHolder.removeClass("tile-view list-view").addClass(viewStyle);
      listHolder.find("div.item").removeClass("col-md-3 col-sm-4 col-md-12").addClass(data.tileSize);
      // var switchType = data.viewStyle.split('-')[0] === "list" : "grid";
      // toggleBtnUl.find("a[data-switch-type=" + switchType + "]").addClass("active");
    };

    function handelMeetingList(data){
      displayMeetings(data, data.total);
      updateMeetingCount(data.total);
      Store.MeetingStore.updateFetchState(false);
      display_applied_filters();
    };

    function updateMeetingState(result) {
      var uuid = result.uuid;
      var status = result.status;
      var item = $(".meeting-card[data-uuid='"+uuid+"']");
      item.removeClass("pending accepted declined");
      item.addClass(status);
      var meetingStatus = ".meeting-"+status;
      var declinedCount = 0;
      var acceptedCount = 0;
      var pendingCount = 0;
      if(result.data.invitees_status_counts) {
        declinedCount = result.data.invitees_status_counts.declined || 0;
        acceptedCount = result.data.invitees_status_counts.accepted || 0;
        pendingCount = result.data.invitees_status_counts.pending || 0;
      }

      var declinedDiv = $(".count", $(".section-count.declined", item));
      var acceptedDiv = $(".count", $(".section-count.accepted", item));
      var pendingDiv = $(".count", $(".section-count.pending", item));
      declinedDiv.html(declinedCount);
      acceptedDiv.html(acceptedCount);
      pendingDiv.html(pendingCount);
      $(meetingStatus,item).removeClass("hide");
      if(status === "accepted") {
        $(".meeting-accept",item).addClass("hide");
      }
      if(status === "declined") {
        $(".meeting-accept",item).addClass("hide");
        $(".meeting-accepted",item).addClass("hide");
        $(".meeting-decline",item).addClass("hide");
      }
      item.addClass(status);
    };

    function updateMeetingCount(count){

      if(Store.MeetingStore.isFilterORSearchApplied()){
        if(count == 0){
          value = i18n.t("zero_search_results");
        }else{
          value = i18n.t("total",{count:count});
        }
      }else{
        value = i18n.t("total",{count:count});
      }

      meetingCount.html(value);
    };

    function displayMeetings(data, showCalendarFeature) {
      var template = HandlebarsTemplates['meeting/meeting-list'];
      var bookMeetingPath = envDetails.urlPrefix + "/meeting_request/new";
      if(typeof jiffle !== "undefined"){
        bookMeetingPath = "/apex/JNBookMeeting" + window.location.search;
      }

      var meetings = _.cloneDeep(data.meetings);
      var calendarFeature = $('.icon-nav-calendar').parents('li');
      if (showCalendarFeature) {
        calendarFeature.show();
      } else {
        calendarFeature.hide();
      }
      meetings.map(function(meeting){
        meeting.pendingCount = meeting.invitees_status_counts.pending || 0;
        meeting.totalInviteeCount = meeting.invitees_status_counts.total_invitees || 0;
        meeting.acceptedCount = meeting.invitees_status_counts.accepted || 0;
        meeting.declinedCount = meeting.invitees_status_counts.declined || 0;
        meeting.meeting_with = meeting.meeting_with || "";
        meeting.fontSize = window.commons.getFontSize(meeting.meeting_with);
      });
      meetingListContainer.html( template({
        meeting_list: meetings,
        toggle_state: data.toggleState,
        book_meeting_path: bookMeetingPath
      }) );
    };

    function display_applied_filters(){
      var template = HandlebarsTemplates['meeting/applied-filters'],
          filters = Store.MeetingStore.getAppliedFilters(),
          context = [];
      for(var i=0;i<filters.types.length;i++){
        context.push({display_name: filters.types[i], filterType: 'types'});
      }
      if(filters.stage){
        context.push({display_name: filters.stage, filterType: 'stage'})
      }else{
        var stageFilter = $("#filter input:radio[name=stage]")
        stageFilter.prop('checked', false)
      }
      appliedFiltersContainer.html(template({filters: context}))

      $('#filter .filter_cb').map(function(){
        if(filters.types.indexOf($(this).data('value')) != -1){
          $(this).prop('checked', true);
        }else{
          $(this).prop('checked', false);
        }
      });
    };

    function setupListeners() {
      toggleBtnUl.on("click", "a.toggle-btn", updateToggleViewState);
      filterStartDate.on('change', updateTimeFilter);
      filterEndDate.on('change', updateTimeFilter);

      globalFilter.on('keyup', _.debounce(searchMeetings, 500));
      filterSearchField.on('keyup', _.debounce(updateSearch, 500));
      $(".filter_panel").on('change', '.filter_cb', function(e){
            var checkbox = $(this);
            var type = checkbox.data('type');
            var value = checkbox.data('value');
            var state = checkbox.prop('checked');
            Actions.updateFilter(type, value, state);
      }).on('click', '.filter_rb', function(e){
        e.stopPropagation();
        Actions.updateStageFilter($(this).data('value'));
      });


      appliedFiltersContainer.on('click', '.remove_filter_icon', function(e){
        e.stopPropagation();
        var elem = $(this);
        Actions.updateAppliedFilters(elem.data('type'), elem.data('value'));
      });

      applyFilterBtn.on('click', applyFilter);
      resetFilterBtn.on('click', resetFilter);
      filterToggleBtn.on('click', function(e){
        e.stopPropagation();
        filter.toggleClass('show');
      });

      $(meetingListContainer).on('click', meetingItem.selector, function(e){
          e.preventDefault();
          e.stopPropagation();
          var uuid = $(this).data('uuid');
          var meeting = Store.MeetingStore.getMeeting(uuid);
          var url = '';

          if(meeting.edit && meeting.status !== "cancelled"){
            url = envDetails.urlPrefix + "/meeting_request/" + uuid + "/edit";
          }else{
            url = envDetails.urlPrefix + "/meeting_request/" + uuid + "/view";
          }

          location.href = url;
      });

      $(meetingListContainer).on('click', bookMeetingBtn.selector, function(e){
        e.stopPropagation();
      });

      $(meetingListContainer).on('click', meetingAcceptBtn.selector, acceptMeeting);
      $(meetingListContainer).on('click', meetingDeclineBtn.selector, declineMeeting);
      $(document).on('click', function(e){
        filter.removeClass('show');
      })

      filter.on('click', function(e){
        e.stopPropagation();
      })

      $('#ui-datepicker-div').on('click', function(e){
        e.stopPropagation();
      })

     $(window).infiniteScroll({
        offset: 200,
        callback: fetchMoreMeetings
      });
    }

    function fetchMoreMeetings() {
      if(Store.MeetingStore.getCurrentPage() <= Store.MeetingStore.getTotalPageCount()){
        Actions.fetchMeetings(Store.MeetingStore.getCurrentPage());
      }
    };

    function updateTimeFilter(){
      if(this.id == 'filter_start_date'){
        Actions.updateTimeFilter('start_date', this.value)
      }else{
        Actions.updateTimeFilter('end_date', this.value)
      }
    };

    function applyFilter(e){
      e.stopPropagation();
      filter.removeClass('show');

      // set global filter
      globalFilter.val(Store.MeetingStore.getSearchValue());
      Actions.applyFilter();
    };

    function resetFilter(e){
      e.stopPropagation();
      Actions.resetFilter();
      $(".filter_panel .filter_cb").prop('checked',false);
      $(".filter_panel .filter_rb").prop('checked', false);
      $(".filter_panel .filter_tb").val('');
      filterSearchField.val('');
      globalFilter.val('');
    };

    function acceptMeeting(e) {
      e.stopPropagation();
      e.preventDefault();
      var item = $(this).closest(meetingItem.selector);
      var uuid = item.data('uuid');
      var url = $(this).data('url');
      Actions.acceptMeeting(uuid, url, 'accepted');
    };

    function declineMeeting(e) {
      e.stopPropagation();
      e.preventDefault();
      var item = $(this).closest(meetingItem.selector);
      var uuid = item.data('uuid');
      var url = $(this).data('url');
      Actions.acceptMeeting(uuid, url, 'declined');
    };

    function searchMeetings(){
      var searchValue = globalFilter.val();
      filterSearchField.val(searchValue);
      Actions.searchMeetings(searchValue);
    };

    function updateSearch(){
      Actions.updateSearch(filterSearchField.val());
    };

    function exportMeetings(e) {
      console.log("Calling Meeting export.....");
      e.preventDefault();
      e.stopPropagation();
      window.location.href = Store.MeetingStore.generateExportUrl();
    }

    return {
        init: init
    };

}());

module.exports = MeetingHandler;



}).call(this,require('_process'),typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {},require("buffer").Buffer,arguments[3],arguments[4],arguments[5],arguments[6],"/app/scripts/Meeting/handler.js","/app/scripts/Meeting")
},{"./actions":2,"./store":4,"_process":9,"buffer":5}],4:[function(require,module,exports){
(function (process,global,Buffer,__argument0,__argument1,__argument2,__argument3,__filename,__dirname){
// var Reflux = require('reflux');
var MeetingActions = require("./actions");
var Api = require('common_api');
// var _ = require('lodash');
// var moment = require('moment');

var MeetingStore = Reflux.createStore({

    init: function () {
        this.listenToMany(MeetingActions);
        this.meetings = [];
        this.toggleStore = {
          'grid': { view: 'tile-view', tile: 'col-md-3 col-sm-4' },
          'list': { view: 'list-view', tile: 'col-md-12' }
        };
        this.filters = { stage: '', types: [], start_date: '', end_date: '', search: '' };
        this.current_page = 1;
        this.total_pages = 0;
        this.fetching = false;
        this.per_page_meeting_count = 10;
        this.toggleState = {
          viewStyle: this.toggleStore[this.getLocalToggle()]['view'],
          tileSize: this.toggleStore[this.getLocalToggle()]['tile']
        }
    },
    generateExportUrl: function(){
      var prefix = envDetails['urlPrefix'] || "";
      var queryString = "?" + $.param(this.getAppliedFilters());

      return [prefix, Api.ENDPOINTS.meeting_request_export, queryString].join("");
    },
    getSearchValue: function(){
      return this.filters.search;
    },

    getLocalToggle: function(key){
      return window.localStorage.getItem('meeting-list') || 'grid';
    },

    isFilterORSearchApplied: function(){
      var isApplied;
      if(this.filters.stage == '' && this.filters.types.length == 0 && this.filters.start_date == '' && this.filters.end_date == '' && this.filters.search == ''){
        isApplied = false;
      }else{
        isApplied = true;
      }
      return isApplied;
    },

    onFetchMeetings: function (page_no) {

        if(this.getFetchState() == false){

          this.filters.page = page_no;
          this.filters.per_page = this.per_page_meeting_count;
          this.updateFetchState(true);

          var promise = Api.fetch({
            url: Api.ENDPOINTS.meetings_list,
            data: this.filters
          });

          promise.then(function (apiResponse) {
            var currentUserUuid = envDetails.currentUser.uuid;
            this.meetings = this.meetings.concat(apiResponse.data.meeting_requests);

            var newlyModifiedId = Number(localStorage.getItem('eventId'));
            var newlyModifiedMeeting = [];
            for (var i = 0, ln = this.meetings.length; i < ln; i++) {
              var meeting = this.meetings[i];
              /*if (typeof meeting === 'undefined') {
                continue;
              }*/
              meeting.primary_sorting_column = new Date(meeting.created_at);
              var stDt = moment(meeting.start_time).utc()._d;
              var edDt = moment(meeting.end_time).utc()._d;
              meeting.startTime = moment(meeting.start_time).utc().format("hh:mm A");
              meeting.endTime = moment(meeting.end_time).utc().format("hh:mm A");
              meeting.meetingDate = stDt.toMediumDate();//moment(meeting.start_time).utc()._d.format("DD MMMM, dddd");
              meeting.invites = meeting.users.internal.length + meeting.users.external.length
              var user = _.find(meeting.users.internal, function(u) {
                return u.uuid == currentUserUuid;
              });
              var meeting_accepted = "hide";
              var meeting_declined = "hide";
              var meeting_accept = "hide";
              var meeting_decline = "hide";
              var invite_status = meeting.invite_status;

              if(meeting.status == 'cancelled'){
                meeting_accept = "hide";
                meeting_decline = "hide";
              }else{
                meeting_accept = invite_status === "pending" ? "" : "hide";
                if(invite_status === "pending" || invite_status === "accepted") {
                  meeting_decline = "";
                }
              }

              meeting_accepted = invite_status === "accepted" ? "" : "hide";
              meeting_declined = invite_status === "declined" ? "" : "hide";

              meeting.user_present = (invite_status !== "");
              meeting.accepted = meeting_accepted;
              meeting.declined = meeting_declined;
              meeting.accept = meeting_accept;
              meeting.decline = meeting_decline;
              meeting.latest = false;

              if (newlyModifiedId === Number(meeting.id)) {
                newlyModifiedMeeting = this.meetings.splice(i, 1);
                ln--;
                i--;
              }
            }

            this.meetings = _.sortBy(this.meetings, function(meeting){
              return meeting.primary_sorting_column;
            });


            if (newlyModifiedMeeting.length > 0) {
              this.meetings.unshift.apply(this.meetings, newlyModifiedMeeting);
            }
            localStorage.removeItem('eventId');

            this.setCurrentPage(this.getCurrentPage() + 1)
            this.setTotalPageCount(Math.ceil(apiResponse.data.total_entries / this.per_page_meeting_count));
            this.trigger({
              type: 'meetinglisting',
              data: {
                meetings: this.meetings,
                toggleState: this.toggleState,
                total: apiResponse.data.total_entries
              }
            });
          }.bind(this));

          promise.catch(function(apiResponse){
            console.log(apiResponse.responseJSON.errors);
            // handle errors..
            this.trigger([]);
          }.bind(this));
        }

    },

    onToggleView: function(selectedView){
      this.toggleState = {
        viewStyle: this.toggleStore[selectedView]['view'],
        tileSize: this.toggleStore[selectedView]['tile']
      }

      this.trigger({ type: 'viewchanged', data: this.toggleState });
    },

    getFetchState: function(){
      return this.fetching;
    },
    updateFetchState: function(state){
      this.fetching = state
    },
    getCurrentPage: function(){
      return this.current_page
    },
    resetMeetingList: function(){
      this.meetings = [];
    },
    setCurrentPage: function(page_no){
      this.current_page = page_no;
    },
    getTotalPageCount: function(){
      return this.total_pages;
    },
    setTotalPageCount: function(count){
      this.total_pages = count;
    },
    onSearchMeetings: function(search_val){
      this.filters.search = search_val;
      this.setCurrentPage(1);
      this.resetMeetingList();
      this.onFetchMeetings(1);
    },
    onUpdateSearch: function(search_val){
      this.filters.search = search_val
    },
    onResetFilter: function(){
      this.filters = { stage: '', types: [], start_date: '', end_date: '', search: '' };
      this.setCurrentPage(1);
      this.resetMeetingList();
      this.onFetchMeetings(1);
    },
    onApplyFilter: function(){
      this.setCurrentPage(1);
      this.resetMeetingList();
      this.onFetchMeetings(1);
    },
    onUpdateFilter: function(type, value, state){
      var filter = this.filters[type];

      if(state) {
        filter.push(value);
      } else {
        var index = filter.indexOf(value);
        if(index > -1) {
          filter.splice(index, 1);
        }
      }
    },
    getAppliedFilters: function(){
      return this.filters
    },
    onUpdateAppliedFilters: function(filterType, value){
      if(filterType == 'types'){
        this.onUpdateFilter(filterType, value, false);
      }else if(filterType == 'stage'){
        this.onUpdateStageFilter('');
      }
      this.setCurrentPage(1);
      this.resetMeetingList();
      this.onFetchMeetings(1);
    },
    onUpdateTimeFilter: function(type, value){
      this.filters[type] = moment(value).format('YYYY-MM-DD');
    },
    onUpdateStageFilter: function(value){
      this.filters.stage = value
    },
    getMeeting: function(uuid){
      var meeting = _.find(this.meetings, function(meeting){
        return meeting.uuid == uuid
      })
      return meeting;
    }
});


var MeetingAcceptDeclineStore = Reflux.createStore({
    init: function () {
        this.listenToMany(MeetingActions);
        this.meetings = [];
        this.filters = { stage: '', types: [], start_date: '', end_date: '', search: '' };
    },
    onAcceptMeeting: function(uuid, url, type) {
      var currentUserUUID = envDetails.currentUser.uuid;
      var promise = Api.update({
        url: url,
        data: {user_uuid: currentUserUUID}
      });

      promise.then(function(data){
          this.trigger({uuid: uuid, status:type,data:data.data});
          console.log(data);
      }.bind(this));

      promise.catch(function(error){
        console.log(error.responseText);
      }.bind(this));
    },
});

module.exports = {
    MeetingStore: MeetingStore,
    MeetingAcceptDeclineStore: MeetingAcceptDeclineStore
}



}).call(this,require('_process'),typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {},require("buffer").Buffer,arguments[3],arguments[4],arguments[5],arguments[6],"/app/scripts/Meeting/store.js","/app/scripts/Meeting")
},{"./actions":2,"_process":9,"buffer":5,"common_api":"common_api"}],5:[function(require,module,exports){
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
},{"_process":9,"base64-js":6,"buffer":5,"ieee754":7,"is-array":8}],6:[function(require,module,exports){
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
},{"_process":9,"buffer":5}],7:[function(require,module,exports){
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
},{"_process":9,"buffer":5}],8:[function(require,module,exports){
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
},{"_process":9,"buffer":5}],9:[function(require,module,exports){
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
},{"_process":9,"buffer":5}],"common_api":[function(require,module,exports){
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
    fetch_env_details: '/meeting_request/new.json',
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
    else if(options['url'] === this.ENDPOINTS.meeting_create){
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
    else if(options['url'] === this.ENDPOINTS.fetch_env_details){
        return this.bookMeetingCallsFS(options.url, options.data);
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
  },

  createMeetingByFS: function(accountID, opptyID, request){
    var promise = new Promise(function(resolve, reject){
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
        var accountID = $.urlParam('accid');
        if(optionData.account_id){
            accountID = optionData.account_id;
        }
        jiffle.JNBookMeeting.getExtAtt(accountID, optionData.per_page, optionData.page, function(result, event) {
            $("#cover").fadeOut();
            if(event.statusCode === 200) {
                var response = (typeof result == "string") ? this.unescapeJSON(result) : result;
                _.forEach(response.data.items, function(item, index){
                    if(!meetingInfo.externalAttendees[item.email]){
                        item['uuid'] = "dummy_" + Math.random().toString(36).substring(2);
                        item['statuses'] =  { verified: false, active: true, approved: null, sso_enabled: false };
                        meetingInfo.externalAttendees[item.email] = _.cloneDeep(item);
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
        jiffle.JNEventMeetingList.getMenuList(params.aID, params.aName, params.oID, params.oName, function(result, event) {
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
  //jiffle.JNBookMeeting = JNBookMeeting;
  jiffle.JNEventMeetingList = JNEventMeetingList;
}

/*mode = 'new';
meetingInfo = {
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
};*/

$(document).ready(function(){

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
        url: Api.ENDPOINTS.fetch_env_details
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
},{"_process":9,"buffer":5}]},{},[1]);
