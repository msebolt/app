
#!/usr/bin/env python

#https://stackoverflow.com/questions/49978705/access-ip-camera-in-python-opencv

import stripe
# This is a sample test API key. Sign in to see examples pre-filled with your key.
stripe.api_key = "sk_test_4eC39HqLyjWDarjtT1zdp7dc"

#depth/object detection
#text/image/speech recognition to 3d object maker (for fish vs shrimp)
#"bots" tagged swarm theory

import os, socket, json, types, shutil#, six
from datetime import datetime

USER_DATA = "data/ur.land/" #os.pardir
RECEIPT_DATA = "data/ur.land/receipt/"
PATH = os.path.abspath(os.path.dirname(__file__))
REL = os.getcwd()

# public
async def index(request):
    return web.FileResponse(PATH + '/index.htm')

async def doc(request): #track views/stars
    name = request.match_info.get('name', 'matt')
    doc = request.match_info.get('doc', 'profile')
    item = request.match_info.get('item', '') #file

    if item == '':
        return web.FileResponse(USER_DATA + name + '/doc/' + doc + '/md')
    else:
        return web.FileResponse(USER_DATA + name + '/doc/' + doc + '/item/' + item)

import glob, re#, whois
from random import randrange

word_path = '/mnt/res/dictionary.txt'
with open (word_path, 'r') as f:
    content = f.read()

words = re.findall("(\n[A-Z]+[0-9 -]*\n)",content)
defs = re.findall("\n[A-Z]+[0-9 -]*\n([\s\S]*?)(?=(\n[A-Z]+[0-9 -]*\n))",content)
NUM_WORDS = 116623 #len(defs) print (len(words)) print (len(defs))
english = dict()

i = 0
while i < len(defs)-1:
    if not words[i].replace('\n', '') in english:
        english[words[i].replace('\n', '')] = defs[i][0] #remove dash?
    else:
        english[words[i].replace('\n', '')] = english[words[i].replace('\n', '')] + defs[i][0] 
    i += 1

async def search(request):
    name = request.match_info.get('name', 'word')
    lookup = await request.text()

    if name == "word":
        if not lookup == "":
            value = english[lookup.upper()]
            if not value is None:
                return web.Response(text=str(value), content_type='text/html')
        else:
            random_num = randrange(NUM_WORDS-1)
            random_word = list(english.keys())[random_num]
            random_def = list(english.values())[random_num].replace('\n', '')
            return web.Response(text=random_word + " : " + random_def, content_type='text/html')
    elif name == "color": #image?
        color = lambda: random.randint(0,255)
        return web.Response(text=random_word + " : " + random_def, content_type='text/html')
    elif name == "ip":
        return web.Response(text=str(request.headers.get('X-FORWARDED-FOR',None)), content_type='text/html')

# private (data)
#import base64
key_file = open('data/ur.land/bit/key.json', mode='r') #include object map...?
key_template = key_file.read()
key_file.close()

def json2obj(data): return json.loads(data, object_hook=lambda d: types.SimpleNamespace(**d))
def obj2json(data): return json.dumps(data.__dict__, indent=4, sort_keys=True, default=lambda o: o.__dict__)

async def user(request):
    name = request.match_info.get('name', 'matt')
    action = request.match_info.get('action', 'check')

    if action == "check":
        return web.Response(text=str(os.path.exists(USER_DATA + name)), content_type='text/html')
    elif action == "create":
        data = await request.post()
        user_client = json2obj(data["user"])
        path = USER_DATA + user_client["name"]
        if not os.path.exists(path):
            shutil.copy('res/template', path)
            key_copy = json2obj(key_template)
            key_copy.name = user_client["name"]
            key_copy.mail = user_client["mail"]
            key_copy.secret = user_client["secret"]
            #send mail...
            with open(path + '/key.json', 'wb') as f:
                f.write(obj2json(key_copy))
            return web.Response(text=obj2json(await scrub(key_copy)), content_type='text/html')

async def scrub(user):
    user.secret = ""
    user.docs = await archive(user.name, "doc", "")
    return user

async def test(request):
    return web.FileResponse('test.htm')
async def cash(request):
    #data = json.loads(await request.json())
    intent = stripe.PaymentIntent.create(amount=1499, currency='usd')
    secret = intent['client_secret']
    return web.Response(text='{"clientSecret":"'+secret+'"}')

async def reset(request):
    mail = user_client["mail"]
    #check mail and send # email temp key...

async def key(name):
    user_file = open(USER_DATA + name + '/key.json', mode='r') #include object map...?
    user_template = key_file.read()
    user_file.close()

    return json2obj(user_template)

async def data(request):
    data = await request.post() #request.json()
    user_client = json2obj(data["user"])
    user_server = key(user_client["name"])

    token = user_client["token"] #add mail support, ip log?
    valid = False
    if token == user_server.token and not user_server.token == "": #check expires...
        valid = True
    else:
        if user_client["secret"] == user_server.secret: #key? 2fa?
            valid = True
            user_server.token = "new"

    if valid is True:
        action = user_client["action"]
        if action == "reset":
            user_server.token = ""
            with open(USER_DATA + user_client["name"] + '/key.json', 'wb') as f:
                f.write(obj2json(user_server))
        elif action == "update":
            user_client["private"] = user_server.private
            with open(USER_DATA + user_client["name"] + '/key.json', 'wb') as f:
                f.write(obj2json(user_client))
        elif action == "pay": #datetime.now().strftime("%d/%m/%Y %H:%M:%S")
            transaction = "random" #generate uuid
            with open(RECEIPT_DATA + user_client["name"] + transaction, 'wb') as f:
                f.write(obj2json(user_client))
        elif action == "search": #add general search term, receipt...
            return await archive(user_client["name"], "general", "")
        elif action == "publish":
            level = user_client["level"] #md item
            sub = user_client["sub"] #new edit delete
            doc = user_client["doc"]
            path = USER_DATA + name + '/doc/' + doc
            if user_client["private"] == "yes":
                private = "x"
            else:
                private = ""
            if level == "md": 
                if sub == "new":
                    if not os.path.exists(path):
                        os.mkdir(path)
                    with open(path + '/md' + private, 'wb') as f:
                        f.write(data["doc"])
                    filename = data['upload'].filename
                    input_file = data['upload'].file
                    content = input_file.read() #check file sizes?
                    with open(os.path.join(path + '/item' + private, filename), 'wb') as f:
                        f.write(content)
                elif sub == "edit":
                    with open(path + '/md' + private, 'wb') as f:
                        f.write(data["doc"])
                elif action == "delete":
                    shutil.rmtree(path)
            elif level == "item":
                item = user_client["item"]
                if sub == "new":
                    filename = data['upload'].filename
                    input_file = data['upload'].file
                    content = input_file.read() #check file sizes?
                    with open(os.path.join(path + '/item' + private, filename), 'wb') as f:
                        f.write(content)
                elif sub == "edit":
                    filename = data['upload'].filename
                    input_file = data['upload'].file
                    content = input_file.read() #check file sizes?
                    with open(os.path.join(path + '/item' + private, filename), 'wb') as f:
                        f.write(content)
                elif sub == "delete":
                    shutil.rmtree(path)

        return web.Response(text=obj2josn(await(scrub(user_server)), content_type='text/html'))

async def share(request):
    name = request.match_info.get('name', 'matt')
    token = request.match_info.get('token', '')
    doc = request.match_info.get('doc', 'manifest')
    item = request.match_info.get('item', '') #file
    
    user_server = user(user_client["name"]) #search/match token ...
    valid = False

    if valid is True:
        action = request.match_info.get('action', '') #get(doc/item)/add(doc)
        if action == "share":
            if item == '':
                return web.FileResponse(DATA + 'ur.land/' + name + '/doc/' + doc + '/mdx')
            else:
                return web.FileResponse(DATA + 'ur.land/' + name + '/doc/' + doc + '/itemx/' + item)
        elif action == "trade":
            data = await request.post()
            path = os.path.dirname(REL) + '/data/ur.land/' + name + '/doc/' + doc + '/itemx/' #+random identifier...
            if not os.path.exists(path):
                os.mkdir(path)
                with open(path + '/doc', 'wb') as f:
                    f.write(data["doc"])

async def archive(name, area, term):
    if area == "doc":
        startpath = USER_DATA + name + '/doc'
        for root, dirs, files in os.walk(startpath):
            level = root.replace(startpath, '').count(os.sep)
            indent = ' ' * 4 * (level)
            print('{}{}/'.format(indent, os.path.basename(root)))
            subindent = ' ' * 4 * (level + 1)
            for f in files:
                print('{}{}'.format(subindent, f))
    elif area == "receipt":
        startpath = RECEIPT_DATA + name
    elif area == "general":
        startpath = USER_DATA + name + '/doc'

# mail 
##(client)
import smtplib, base64, ssl
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

SMTP_RELAY = "relay.dynu.com"
SMTP_LOGIN = "relay@relay.dralun.me"
SMTP_PASSWORD = ""
SMTP_EMAIL = "dr@dralun.me"

def sendMail(to, subject, template, parameters):
    context = ssl.create_default_context()

    with smtplib.SMTP(SMTP_RELAY, 587) as server:
        server.starttls(context=context)
        server.login(SMTP_LOGIN, SMTP_PASSWORD)
        message = MIMEMultipart("alternative")
        message["Subject"] = subject
        message["From"] = SMTP_EMAIL
        message["To"] = to
        message_template = HEADER + template + FOOTER
        for parameter in parameters:
            message_template = message_template.replace('####', parameter)
        part1 = MIMEText(message_template, "plain")
        part2 = MIMEText(message_template, "html")
        message.attach(part1)
        message.attach(part2)
        server.send_message(message)

##(server)
import threading, email, uuid
from aiosmtpd.controller import Controller

class MailHandler():
    async def handle_RCPT(self, server, session, envelope, address, rcpt_options):
        if not address.endswith('@ur.land'): #use variable...
            return '550 not relaying to that domain'
        envelope.rcpt_tos.append(address)
        return '250 OK'

    async def handle_DATA(self, server, session, envelope): #check len(data) just in case...
        # filter project@user.servius.me
        #print('Message from %s' % envelope.mail_from)
        #print('Message for %s' % envelope.rcpt_tos)
        #print('Message data:\n')
        #message = email.message_from_string(envelope.content.decode('utf8', errors='replace'))
        mail_id = str(uuid.uuid4())

        if os.path.exists(REL + '/data/mail/' + str(envelope.rcpt_tos)):
            with open(REL + '/data/mail/' + str(envelope.rcpt_tos) + '/' + mail_id, 'w') as f:
                f.write(envelope.content.decode('utf8', errors='replace'))

        return '250 Message accepted for delivery'

def handleAttachment():
    counter = 1
    for part in msg.walk():
        if part.get_content_maintype() == 'multipart': # multipart/* are just containers
            continue
        filename = part.get_filename() # Applications should really sanitize the given filename so that an email message can't be used to overwrite important files
        if not filename:
            ext = mimetypes.guess_extension(part.get_content_type())
            if not ext:
                ext = '.bin'
            filename = 'part-%03d%s' % (counter, ext)
        counter += 1
        fp = open(os.path.join(opts.directory, filename), 'wb')
        fp.write(part.get_payload(decode=True))
        fp.close()

# server
import asyncio, aiohttp
from aiohttp import web
from concurrent.futures import ProcessPoolExecutor

def run(part, *args):
    loop = asyncio.new_event_loop()

    try:
        full = part(*args)
        asyncio.set_event_loop(loop)
        loop.create_task(full)
        loop.run_forever()
    finally:
        loop.close()

async def site(port):
    app = web.Application(client_max_size=10000000)

    app.router.add_static('/static', '/mnt/res')
    app.add_routes([web.post('/cash', cash)])

    app.add_routes([web.get('/test', test)])
    app.add_routes([web.get('/', index)])

    app.add_routes([web.get('/user/{name}/{action}', user)])

    app.add_routes([web.get('/{name}', index)])
    app.add_routes([web.get('/{name}/{doc}', doc)])
    app.add_routes([web.get('/{name}/{doc}/{item}', doc)])
    #app.add_routes([web.get('/{domain}/{user}/{doc}/{item}', doc)])
    
    app.add_routes([web.post('/data', data)])

    app.add_routes([web.post('/search/{name}', search)])
    
    runner = web.AppRunner(app)
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    await runner.setup()

    site = web.TCPSite(runner, 'localhost', 5000+port)
    await site.start()

async def mail(port):
    controller = Controller(MailHandler(), hostname='localhost', port=5000+port)
    controller.start()

try:
    loop = asyncio.get_event_loop()
    executor = ProcessPoolExecutor(max_workers=14)
    loop.run_in_executor(executor, run, site, 1) #from haproxy
    #loop.run_in_executor(executor, run, mail, 2)

    loop.run_forever()
except:
    pass
finally:
    for runner in runners:
        loop.run_until_complete(runner.cleanup())
