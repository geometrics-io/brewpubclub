var express = require('express');
var router = express.Router();
var pg = require('pg');
process.env.USER = 'postgres';
process.env.PGUSER = 'postgres';
var knex = require('knex')({
    client: 'pg',
    connection: 'pg://postgres:6GLp29Fd4B:L@localhost:5432/brewery',
    debugging: 'true'
    //searchPath: 'knex,public'
});

/* GET home page. */
router.route('/').get(function (req, res) {
    res.render('index', {title: 'Express'});
});

// router to get all the data

router.route('/api/members').get(function(req, res) {
    knex.select('*').from('bigpicture').then(function(rows) {return res.json(rows)});
});

// router to add a new member

router.route('/api/members').post(function(req, res) {
    console.log(req.body);
    var memberAdd = {firstname: req.body.firstname, lastname: req.body.lastname};
    var altMember = {firstname: req.body.alt_firstname, lastname: req.body.alt_lastname};
    console.log(altMember);
    var contactinfo = {
        street: req.body.street,
        city: req.body.city,
        state: req.body.state,
        zip: req.body.zip,
        phone: req.body.phone,
        email: req.body.email
    };
    var member_status_info = {
        start_date: req.body.start_date,
        membership: req.body.membership
    };
    console.log(member_status_info);
    console.log('alt first name: ' + altMember.firstname);

    knex('members').insert(memberAdd).then(function () {
        return knex('members').max('membernumber as membernumber').where(memberAdd)
            .then(function (currentMember) {
                console.log(currentMember[0]);
                var contactdata = Object.assign({},currentMember[0],contactinfo);
                knex('contact')
                    .insert(contactdata)
                    .then(function() {
                    });
                var alt_member_data = Object.assign({},currentMember[0],altMember);
                knex('alternate_member')
                    .insert(alt_member_data)
                    .then(function(){
                        console.log('alternate member added')
                    });

                var member_status_data = Object.assign({},currentMember[0],member_status_info);
                knex('member_status').insert(member_status_data)
                    .then(function() {
                        console.log('member_status_data added');
                        knex('member_status').where({'membernumber': member_status_data.membernumber})
                            .then(function (memstat) {
                                return knex('units_view')
                                    .where(memstat[0])
                                    .then(function (units_view) {
                                        knex('member_transactions').insert({
                                                'membernumber': units_view[0].membernumber,
                                                'memstat_id': units_view[0].memstat_id,
                                                'raw_units': 0
                                            })
                                            .then(function () {
                                                knex('member_status')
                                                    .where('memstat_id', units_view[0].memstat_id)
                                                    .update({'total_raw_units': units_view[0].units})
                                                    .then(function () {
                                                        knex('bigpicture').where('memstat_id', units_view[0].memstat_id)
                                                            .then(function (rows) {
                                                                console.log(rows);
                                                                return res.json({memberadd: "complete"})
                                                            });
                                                    });
                                            });
                                    });
                            });
                    });
            });
    });
});

// router to get the member to update, this can probably be removed

router.route('/api/updateMember').get(function(req, res) {
    knex.select('*').from('bigpicture').then(function(rows) {return res.json(rows)});
});

// router to update member

router.route('/api/updateMember').post(function(req, res){
    var memberUpdate = {
        firstname: req.body.firstname,
        lastname: req.body.lastname};
    var altMember = {
        firstname: req.body.alt_firstname,
        lastname: req.body.alt_lastname
    };
    var contactinfo = {
        street: req.body.street,
        city: req.body.city,
        state: req.body.state,
        zip: req.body.zip,
        phone: req.body.phone,
        email: req.body.email
    };
    var member_status_info = {
        start_date: req.body.start_date,
        membership: req.body.membership,
        memstat_id: req.body.memstat_id
    };
    console.log(member_status_info);
    var memnum =  req.body.membernumber;
    var memstatid = req.body.memstat_id;
    knex('members').where('membernumber',memnum).update(memberUpdate)
        .then(function()
        {
            knex('alternate_member').where('membernumber',memnum).update(altMember)
                .then(function()
                {
                    knex('contact').where('membernumber', memnum).update(contactinfo)
                        .then(function ()
                        {
                            knex('member_status').where({memstat_id: memstatid, membernumber: memnum})
                                .update(member_status_info).then(function() {
                                    var msimembership = member_status_info.membership;
                                    knex('membership_level_raw_units').select('units')
                                        .where({name:msimembership})
                                        .then(function(units) {
                                            var theunits = units[0].units;
                                            //console.log('memstatid: ' + memstatid);
                                            //console.log('theunits: ' + theunits);
                                            //console.log('memnum: ' + memnum);
                                            var theseunits = {total_raw_units: theunits};
                                            //console.log('theseunits: ' + theseunits.total_raw_units);
                                            knex('member_status').where({memstat_id: memstatid, membernumber: memnum})
                                                .update({total_raw_units: theunits})
                                                .then( function () {
                                                    console.log('membernumber: '
                                                        + memnum + ' | memstat_id: '
                                                        + memstatid + ' --> updated to '
                                                        + member_status_info.membership);
                                                });
                                        })
                                })
                                .then(function ()
                                {
                                    knex.select('*').from('bigpicture')
                                })
                                .then(function (rows)
                                {
                                    return res.json(rows)
                                })
                        })
                })
        })
});

// router to add membership to existing member

router.route('/api/addMembership').post(function(req, res){
  var add_membership = {
    membernumber: req.body.membernumber,
    membership: req.body.membership,
    start_date: req.body.start_date
  };
  knex('membership_levels').where('name',add_membership.membership)
    .then( function(new_units) {
      var total_raw = {'total_raw_units': new_units[0].units * new_units[0].unit_base};
      var add_membership_data = Object.assign({},total_raw,add_membership);
      knex('member_status').insert(add_membership_data)
        .then(function() {
          return knex('member_status').where({'membernumber':add_membership_data.membernumber})
            .max('memstat_id as memstat_id')
            .then(function(new_memstat_id) {
              console.log('got max memstat_id')
              var memst_data = {'membernumber': add_membership_data.membernumber, raw_units: 0};
              var memst_id = new_memstat_id[0];
              var add_mem_trans = Object.assign({}, memst_id, memst_data);
              knex('member_transactions').insert(add_mem_trans).then(function () {
                knex.select('*').from('bigpicture')
                  .then(function (rows) {
                    return res.json(rows)
                  })
              })
            })
        })
    });

});

// Renew a current members existing membership

router.route('/api/renewMember').post(function(req, res) {
    var membernumber = req.body.membernumber;
    var memstatid = req.body.memstat_id;
    console.log('membernumber: ' + membernumber + ' | memstat_id: ' + memstatid);
    knex('member_status').where('memstat_id', memstatid).then(function(memstatdata){
        console.log(memstatdata[0]);
        var current_units = Number(memstatdata[0].total_raw_units);
        var current_start = memstatdata[0].start_date;
        console.log(current_start);
        knex('membership_level_raw_units').where('name',memstatdata[0].membership).then(function(units) {
            console.log(memstatdata[0]);
            var newstart = new Date(current_start.setFullYear(current_start.getFullYear() + 1));
            var new_total = Number(units[0].units) + current_units;
            knex('member_status').where('memstat_id', memstatdata[0].memstat_id)
                .update({'total_raw_units': new_total, 'start_date': newstart})
                .then(function() {
                    knex.select('*').from('bigpicture').where('memstat_id', memstatid).then(function (thememb) {
                        return res.json(thememb)
                    });
                });
        });
    })
});


router.route('/api/addUnits').post(function(req, res) {
    var member_trans = req.body;
    console.log(member_trans);
    knex('member_transactions').insert(member_trans).then(function() {
        return knex('bigpicture').where({'memstat_id': member_trans.memstat_id})
            .then(function(thememb) {return res.json(thememb)});
    });
});

module.exports = router;

