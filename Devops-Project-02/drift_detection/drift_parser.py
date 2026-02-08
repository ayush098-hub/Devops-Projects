import json
f = open('plan.json',)
data = json.load(f)


resources = data['resource_changes']

for i in range(len(resources)):
    action = resources[i]['change']['actions'][0]
    if action!='no-op':
        print("Drift Detected for the below resource:")
        print("Resource Type: ",resources[i]['type'])
        print("Resource is: ",resources[i]['address'])
        print("Action is going to perform: ",action)
        print("Before: ",resources[i]['change']['before'])
        print("After: ",resources[i]['change']['after'])

    
