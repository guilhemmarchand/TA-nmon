###
FAQ
###

**Can I have my own nmon collection while running the TA-nmon ?**

For some reason, you may want to have your own collection of nmon files and run the TA-nmon in the same time.
The TA-nmon will not have trouble if your run your own collection, the answer is yes you can.

Note that it is not recommended to try using those files instead of the TA-nmon processing stuff, for performance and CPU foot print reasons.

**Can I have the TA-nmon and the TA-Unix in the same time ?**

You might need the TA-unix for specific tasks that are out of the scope of the Nmon application, such as ingesting security related data.

Running both addons in same servers is not a problem at all.

The TA-nmon is CIM compatible, for most performance related metrics, the TA-nmon can be transparently used in replacement of the TA-Unix.

**Is the TA-nmon CIM compatible ?**

Yes it is. The TA-nmon is CIM compatible, it will specially deal with the following CIM data models:

- Application State
- Inventory
- Network Traffic
- Performance

If you are an Enterprise Security customer for instance, all you need is having the TA-nmon deployed in search heads as well.
