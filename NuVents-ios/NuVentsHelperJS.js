var getDayDifferenceWithinAMonth = function(epoch, epochToday) {
    var today = new Date(epochToday * 1000); // Today date
    var date = new Date(epoch * 1000); // Event date
    // Check if year & month is same, if not return -1
    if (today.getFullYear() == date.getFullYear() && today.getMonth() == date.getMonth()) {
        // Less than month difference
        return date.getDate() - today.getDate()
    } else {
        // More than month difference
        return -1
    }
}

var getHumanReadableDate = function(epoch, epochToday) {
    var monthNames = new Array('January', 'February', 'March',
                            'April', 'May', 'June', 'July', 'August', 'September',
                            'October', 'November', 'December');
    var today = new Date(epochToday * 1000); // Today date
    var date = new Date(epoch * 1000); // Event date
    if (today.getFullYear() == date.getFullYear() && today.getMonth() == date.getMonth() && today.getDate() == date.getDate()) {
        // Today's event
        return 'Today at ' + convertTime(date.getHours() + ':' + date.getMinutes())
    } else if (today.getFullYear() == date.getFullYear() && today.getMonth() == date.getMonth() && today.getDate() == (date.getDate() - 1)) {
        // Tomorrow's event
        return 'Tomorrow at ' + convertTime(date.getHours() + ':' + date.getMinutes())
    } else {
        // Other day's event
        return monthNames[date.getMonth()] + ' ' + date.getDate() + getDateOrd(date.getDate()) + ' at ' + convertTime(date.getHours() + ':' + date.getMinutes())
    }
}

var convertTime = function(time) {
    // Check correct time format and split into components
    var timeS = time.split(':')
    hour = parseFloat(timeS[0])
    min = parseFloat(timeS[1])

    if (time.indexOf('12:0') > -1) {
        return 'noon'
    } else if (hour == 0 && min == 0) {
        return '12 AM'
    } else if (hour == 0 && min > 0) {
        return '12:' + min + ' AM'
    } else if (hour < 12 && min == 0) {
        return hour + ' AM'
    } else if (hour < 12 && min > 0) {
        return timeS.join(':') + ' AM'
    } else if (hour == 12 && min > 0) {
        return timeS.join(':') + ' PM'
    } else if (hour > 12 && min == 0) {
        return (hour - 12) + ' PM'
    } else if (hour > 12 && min > 0) {
        return (hour - 12) + ':' + min + ' PM'
    } else {
        return timeS.join(':')
    }
}

var getDateOrd = function(date) {
    switch(date) {
        case 1:
        case 21:
        case 31:
            return 'st';
        case 2:
        case 22:
            return 'nd';
        case 3:
        case 23:
            return 'rd';
        default:
            return 'th';
    }
}