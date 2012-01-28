import time


def json_handler(obj):
    """
    JSON parser object, which helps serializer to parse
    * datetime objects
    and soon more. Probably.
    """
    if hasattr(obj, 'timetuple'):
        return time.mktime(obj.timetuple()) * 1000
    else:
        message = "Object {} is not JSON serializable"
        raise TypeError(message.format(repr(obj)))
