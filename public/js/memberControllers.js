/**
 * Created by nomadic on 11/16/15.
 */

angular.module('memberApp',['ui.router','ngResource','memberApp.controllers','memberApp.services']);

angular.module('memberApp.controllers',[]).controller('MemberListController',function($scope,$state,popupService,$window,Member){

    $scope.members=Member.query();

    $scope.deleteMember=function(member){
        if(popupService.showPopup('Really delete this?')){
            member.$delete(function(){
                $window.location.href='';
            });
        }
    }

}).controller('MemberViewController',function($scope,$stateParams,Member){

    $scope.member=Member.get({id:$stateParams.id});

}).controller('MemberCreateController',function($scope,$state,$stateParams,Member){

    $scope.member=new Member();

    $scope.addMember=function(){
        $scope.member.$save(function(){
            $state.go('members');
        });
    }

}).controller('MemberEditController',function($scope,$state,$stateParams,Member){

    $scope.updateMember=function(){
        $scope.member.$update(function(){
            $state.go('members');
        });
    };

    $scope.loadMember=function(){
        $scope.member=Member.get({id: $stateParams.id });
    };

    $scope.loadMember();
});

angular.module('memberApp.services',[]).factory('Member',function($resource){
    return $resource('/api/members/:id',{id: '@_id'}, {
        update: {
            method: 'PUT'
        }
    });
}).service('popupService',function($window){
    this.showPopup=function(message){
        return $window.confirm(message);
    }
});

angular.module('memberApp.services').factory('Entry', function($resource) {
    return $resource('/api/members/:id', { id: '@_id' }, {
        update: {
            method: 'PUT' // this method issues a PUT request
        }
    }, {
        stripTrailingSlashes: false
    });
});