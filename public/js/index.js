// angular.module('ui.bootstrap.demo', ['ngAnimate', 'ui.bootstrap']);
angular.module('memberApp', ['ngAnimate', 'ui.bootstrap', 'ui.router', 'ngResource'])
    .config(function ($stateProvider, $httpProvider) {
        $stateProvider.state('view', {
            url: 'view',
            templateUrl: 'views/view.html',
            controller: 'TypeaheadCtrl',
            reload: 'true'
        }).state('new', {
            url: 'new',
            templateUrl: 'views/newform.html',
            controller: 'TypeaheadCtrl'
        }).state('edit', {
            url: 'edit',
            templateUrl: 'views/editform.html',
            controller: 'TypeaheadCtrl'
        }).state('renew', {
            url: 'renew',
            templateUrl: 'views/renew.html',
            controller: 'TypeaheadCtrl'
        });
    }).run(function ($state) {
    $state.go('view');
}).controller('TypeaheadCtrl', function ($scope, $http, $filter) {

//This section controls the pint and growler buttons

        var pintCount = 0;
        var growlerCount = 0;

        $scope.pint = "Pint";

        $scope.growler = "Growler";

        $scope.pintButton = function (x) {
            pintCount += x;
            $scope.pint = pintCount + " Added";
        };

        $scope.growlerButton = function (x) {
            growlerCount += x;
            $scope.growler = growlerCount + " Added";
        };

        //$scope.pintButton = function () {
        //    pintCount += 1;
        //    $scope.pint = pintCount + " Added";
        //};
        //
        //$scope.growlerButton = function () {
        //    growlerCount += 1;
        //    $scope.growler = growlerCount + " Added";
        //};

//The code below fills the typeahead dropdown with information from the database

        $scope.selected = undefined;

        $http.get('/api/members').success(function (data) {
            $scope.memberData = data;
        });

        var todays_date = new Date().toISOString().slice(0, 10);

        $scope.themember = {member_name: "", start_date: todays_date};

        $scope.$watch('themember.start_date', function (formattedDate) {
            $scope.themember.start_date = $filter('date')(formattedDate, 'yyyy-MM-dd');
        });

        $scope.addUnit = function () {
            //console.log($scope.themember);
            var data = {
                'membernumber': $scope.themember.membernumber,
                'memstat_id': $scope.themember.memstat_id,
                'raw_units': $scope.themember.raw_units
            };

            $http.post("/api/addUnits", data).success(function (data, status, headers) {
                $scope.themember = data[0];
                console.log('it worked');
            })
        };

        $scope.updateMember = function () {
            var data = $scope.themember;
            console.log(data);
            if (data.directive === 'editUser') {
                console.log('pushing update for member edit');

                $http.post("/api/updateMember", data).success(function (data, status, headers) {
                    console.log(data[0]);
                    console.log('Member Updated');
                })
            }
            else
            if (data.directive === 'addMembership') {
              console.log('made it here to where data.directive does eq addMembership');
              console.log('pushing update for additional membership');

              $http.post("/api/addMembership", data).success(function (data, status, headers) {
                console.log(data[0]);
                console.log('directive: ' + data[0].directive);
                console.log('Membership Updated');
              })
            }
            };

        $scope.renewMember = function () {
            var data = $scope.themember;
            console.log(data);
            $http.post("/api/renewMember", data).success(function (data, status, headers) {
                console.log(data);
                $scope.themember = data[0];
            })
        };

//$scope.themember = new Member();

        $scope.addMember = function () {
            var data = $scope.themember;
            console.log(data);
            $http.post("/api/members", data).success(function (data, status, headers) {
                console.log('member added');
            });

        };

//Datepicker for the new member form

        $scope.clear = function () {
            $scope.themember.start_date = null;
        };

        $scope.open = function ($event) {
            $scope.status.opened = true;
        };

        $scope.setDate = function (year, month, day) {
            $scope.themember.start_date = new Date(year, month, day);
        };

        $scope.dateOptions = {
            formatYear: 'yyyy',
            startingDay: 1
        };

        $scope.formats = 'yyyy-MM-dd';
        // $scope.format = $scope.formats[0];

        $scope.status = {
            opened: false
        };

//This redirects pages back to the index.html when submitted or saved

        $scope.indexRedirect = function () {
            location = "/";
        }
    }
);
