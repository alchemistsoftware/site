const github_username = 'cabarger'
const templates_path = "/templates"

interface route_entry {
    TemplatePath: string,
    Title: string,
    Description: string,
};

const routes_map = new Map();
let caleb_github_events: Object[] = [];

function normalizePath(path: string): string {
    const is_absolute = path.startsWith('/');
    const parts = path.split('/');
    const normalized_parts = [];

    for (const part of parts) {
        if (part === '..') {
            if (normalized_parts.length > 0) {
                normalized_parts.pop();
            } else if (!is_absolute) {
                normalized_parts.push(part);
            }
        } else if (part !== '.' && part !== '') {
            normalized_parts.push(part);
        }
  }

    let normalized_path = normalized_parts.join('/');
    if (is_absolute) normalized_path = `/${normalized_path}`;
    return normalized_path;
}

async function generateRoutes(path: string): Promise<void> {
    let promise = new Promise<void>((resolve) => { 
    const normalized_path = normalizePath(path);
    fetch(normalized_path as any as URL)
        .then(res => res.text())
        .then(html => {
            const parser = new DOMParser();
            const doc = parser.parseFromString(html, 'text/html');
            const links = doc.querySelectorAll('a');

            const file_names = Array.from(links)
                .map((link: any) => link.textContent.trim());

            file_names.forEach((file_name: string) => {
                if (file_name.endsWith('/')) { // This is a directory
                    generateRoutes(`${normalized_path}/${file_name}`);
                } else {
                    const loose_the_html = file_name.replace(/\.[^/.]+$/, '');
                    routes_map.set(loose_the_html, {
                        TemplatePath: `${normalized_path}/${file_name}`,
                        Title: `Alchemist: ${loose_the_html}`,
                        Description: `This is the ${loose_the_html} page`,
                    });
                }
            }); 
            resolve();
        });
    });
    return (await promise);
}

async function getGithubEvents(): Promise<Object[]> {
    if (caleb_github_events.length > 0)
        return caleb_github_events;

    let promise = new Promise<Object[]>((resolve) => {
        fetch(`https://api.github.com/users/${github_username}/events/public`)
            .then((Response) => {
                Response.text()
                    .then((response_json) => {
                        caleb_github_events = JSON.parse(response_json);
                        resolve(caleb_github_events);
                    });
            });
    });

    return (await promise);
}

function TryGetElementByID(ElemId: string): HTMLElement {
    const Elem = document.getElementById(ElemId);
    if (Elem == null) {
        throw `Element with id: '${ElemId}' wasn't found.`;
    }
    return Elem;
}

const LocationHandler = async () => {
    // Make sure routes have been generated
    if (routes_map.size == 0) 
        await generateRoutes('/templates')
    
    let Location: string = window.location.hash.replace("#", "");
    if (Location.length == 0) {
        Location = "home";
    }

    const Route = routes_map.get(Location);
    TryGetElementByID("content").innerHTML =
        await fetch(Route.TemplatePath)
            .then((Response) => Response.text());

    // Do a specific thing depending on template
    switch (Location)
    {
        case "home": {
            const activity_element = TryGetElementByID("activity"); 
            getGithubEvents().then(events => {
                events.forEach((event: any) => {
                    if (event.type == "PushEvent") {
                        let card = document.createElement("div");
                        card.className = "card"

                        let push_info = document.createElement("p");
                        push_info.innerHTML = event.created_at.slice(0, 10) + ": pushed " + event.payload.commits.length + " commits to " + `<a href="https://github.com/${event.repo.name}">${event.repo.name}</a>`;
                        card.appendChild(push_info);
                        event.payload.commits.forEach((commit: any) => {
                            let commit_message = document.createElement("p");
                            commit_message.innerHTML = commit.message;
                            card.appendChild(commit_message);
                        });
                        activity_element.appendChild(card);
                    }
                });
            });
        } break;
        case "posts": {
            const normalized_path = templates_path + '/posts';
            fetch(normalized_path as any as URL)
                .then(res => res.text())
                .then(html => {
                    const posts_ul = TryGetElementByID("posts");
                    const parser = new DOMParser();
                    const doc = parser.parseFromString(html, 'text/html');
                    const links = doc.querySelectorAll('a');

                    for (const link of links) {
                        const post_li = document.createElement("li");
                        const post_a = document.createElement("a");
                        if (link.textContent) {
                            post_a.innerText = link.textContent.trim().replace(/\.[^/.]+$/, '');
                            post_a.href = `#${link.textContent.trim().replace(/\.[^/.]+$/, '')}`;
                        }
                        post_li.appendChild(post_a);
                        posts_ul.appendChild(post_li);
                    }
                });
        } break;
        case "protex": {
            TryGetElementByID("changelog").innerHTML =
                await fetch("/templates/protex_changelog.html")
                    .then((Response) => Response.text());
        } break;
        default: break;
    };

    document.title = Route.Title;
    const DescElem = document.querySelector('meta[name="description"]');
    if (DescElem !== null) {
        DescElem.setAttribute("content", Route.Description);
    }
};

window.addEventListener("hashchange", LocationHandler);
LocationHandler();
