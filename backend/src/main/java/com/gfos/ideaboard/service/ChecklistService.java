package com.gfos.ideaboard.service;

import com.gfos.ideaboard.dto.ChecklistItemDTO;
import com.gfos.ideaboard.entity.ChecklistItem;
import com.gfos.ideaboard.entity.Idea;
import com.gfos.ideaboard.entity.User;
import com.gfos.ideaboard.entity.UserRole;
import com.gfos.ideaboard.exception.ApiException;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.transaction.Transactional;
import java.util.List;
import java.util.stream.Collectors;

@ApplicationScoped
public class ChecklistService {

    private static final int MAX_TITLE_LENGTH = 200;

    @PersistenceContext(unitName = "IdeaBoardPU")
    private EntityManager em;

    public List<ChecklistItemDTO> getChecklistByIdea(Long ideaId) {
        List<ChecklistItem> items = em.createNamedQuery("ChecklistItem.findByIdea", ChecklistItem.class)
                .setParameter("ideaId", ideaId)
                .getResultList();

        return items.stream()
                .map(ChecklistItemDTO::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional
    public ChecklistItemDTO createChecklistItem(Long ideaId, String title, Long currentUserId) {
        // Eingabe validieren
        if (title == null || title.trim().isEmpty()) {
            throw ApiException.badRequest("Checklistenelement-Titel ist erforderlich");
        }
        if (title.length() > MAX_TITLE_LENGTH) {
            throw ApiException.badRequest("Checklistenelement-Titel muss " + MAX_TITLE_LENGTH + " Zeichen oder weniger sein");
        }

        Idea idea = em.find(Idea.class, ideaId);
        if (idea == null) {
            throw ApiException.notFound("Idee nicht gefunden");
        }

        // Nur der Ideenschöpfer kann Checklistenelemente hinzufügen
        if (!idea.getAuthor().getId().equals(currentUserId)) {
            throw ApiException.forbidden("Nur der Ideenschöpfer kann Checklistenelemente hinzufügen");
        }

        // Nächste Ordinalposition abrufen
        Integer maxPosition = em.createQuery(
                "SELECT COALESCE(MAX(c.ordinalPosition), -1) FROM ChecklistItem c WHERE c.idea.id = :ideaId", Integer.class)
                .setParameter("ideaId", ideaId)
                .getSingleResult();

        ChecklistItem item = new ChecklistItem();
        item.setIdea(idea);
        item.setTitle(title.trim());
        item.setIsCompleted(false);
        item.setOrdinalPosition(maxPosition + 1);

        em.persist(item);

        // Ideenfortschritt basierend auf der Checkliste aktualisieren
        updateIdeaProgress(idea);

        return ChecklistItemDTO.fromEntity(item);
    }

    @Transactional
    public ChecklistItemDTO toggleChecklistItem(Long ideaId, Long itemId, Long currentUserId) {
        Idea idea = em.find(Idea.class, ideaId);
        if (idea == null) {
            throw ApiException.notFound("Idee nicht gefunden");
        }

        // WICHTIG: Nur der Ideenschöpfer kann Elemente abhaken
        if (!idea.getAuthor().getId().equals(currentUserId)) {
            throw ApiException.forbidden("Nur der Ideenschöpfer kann Checklistenelemente aktualisieren");
        }

        ChecklistItem item = em.find(ChecklistItem.class, itemId);
        if (item == null) {
            throw ApiException.notFound("Checklistenelement nicht gefunden");
        }

        // Prüfe, ob das Element zu dieser Idee gehört
        if (!item.getIdea().getId().equals(ideaId)) {
            throw ApiException.badRequest("Checklistenelement gehört nicht zu dieser Idee");
        }

        // Fertigstellungsstatus umschalten
        item.setIsCompleted(!item.getIsCompleted());
        em.merge(item);

        // Ideenfortschritt basierend auf Checklistenfertigstellung aktualisieren
        updateIdeaProgress(idea);

        return ChecklistItemDTO.fromEntity(item);
    }

    @Transactional
    public void deleteChecklistItem(Long ideaId, Long itemId, Long currentUserId) {
        Idea idea = em.find(Idea.class, ideaId);
        if (idea == null) {
            throw ApiException.notFound("Idee nicht gefunden");
        }

        // Nur der Autor kann Checklistenelemente löschen
        if (!idea.getAuthor().getId().equals(currentUserId)) {
            throw ApiException.forbidden("Nur der Ideenschöpfer kann Checklistenelemente löschen");
        }

        ChecklistItem item = em.find(ChecklistItem.class, itemId);
        if (item == null) {
            throw ApiException.notFound("Checklistenelement nicht gefunden");
        }

        // Prüfe, ob das Element zu dieser Idee gehört
        if (!item.getIdea().getId().equals(ideaId)) {
            throw ApiException.badRequest("Checklistenelement gehört nicht zu dieser Idee");
        }

        em.remove(item);

        // Ideenfortschritt aktualisieren
        updateIdeaProgress(idea);
    }

    @Transactional
    public ChecklistItemDTO updateChecklistItem(Long ideaId, Long itemId, String title, Long currentUserId) {
        Idea idea = em.find(Idea.class, ideaId);
        if (idea == null) {
            throw ApiException.notFound("Idee nicht gefunden");
        }

        // Nur der Autor kann Checklistenelemente aktualisieren
        if (!idea.getAuthor().getId().equals(currentUserId)) {
            throw ApiException.forbidden("Nur der Ideenschöpfer kann Checklistenelemente aktualisieren");
        }

        if (title == null || title.trim().isEmpty()) {
            throw ApiException.badRequest("Checklistenelement-Titel ist erforderlich");
        }
        if (title.length() > MAX_TITLE_LENGTH) {
            throw ApiException.badRequest("Checklistenelement-Titel muss " + MAX_TITLE_LENGTH + " Zeichen oder weniger sein");
        }

        ChecklistItem item = em.find(ChecklistItem.class, itemId);
        if (item == null) {
            throw ApiException.notFound("Checklistenelement nicht gefunden");
        }

        // Prüfe, ob das Element zu dieser Idee gehört
        if (!item.getIdea().getId().equals(ideaId)) {
            throw ApiException.badRequest("Checklistenelement gehört nicht zu dieser Idee");
        }

        item.setTitle(title.trim());
        em.merge(item);

        return ChecklistItemDTO.fromEntity(item);
    }

    /**
     * Aktualisiert den Fortschrittsprozentsatz der Idee basierend auf der Checklistenfertigstellung.
     * Fortschritt = (fertiggestellte Elemente / Gesamtelemente) * 100
     */
    private void updateIdeaProgress(Idea idea) {
        List<ChecklistItem> items = em.createNamedQuery("ChecklistItem.findByIdea", ChecklistItem.class)
                .setParameter("ideaId", idea.getId())
                .getResultList();

        if (items.isEmpty()) {
            // Keine Checklistenelemente, Fortschritt nicht ändern
            return;
        }

        long completedCount = items.stream()
                .filter(ChecklistItem::getIsCompleted)
                .count();

        int progressPercentage = (int) Math.round((double) completedCount / items.size() * 100);
        idea.setProgressPercentage(progressPercentage);
        em.merge(idea);
    }
}
