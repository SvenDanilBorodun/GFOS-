package com.gfos.ideaboard.service;

import com.gfos.ideaboard.entity.Idea;
import com.gfos.ideaboard.entity.IdeaStatus;
import com.gfos.ideaboard.entity.User;
import com.itextpdf.io.font.constants.StandardFonts;
import com.itextpdf.kernel.colors.ColorConstants;
import com.itextpdf.kernel.font.PdfFont;
import com.itextpdf.kernel.font.PdfFontFactory;
import com.itextpdf.kernel.pdf.PdfDocument;
import com.itextpdf.kernel.pdf.PdfWriter;
import com.itextpdf.layout.Document;
import com.itextpdf.layout.element.Cell;
import com.itextpdf.layout.element.Paragraph;
import com.itextpdf.layout.element.Table;
import com.itextpdf.layout.properties.TextAlignment;
import com.itextpdf.layout.properties.UnitValue;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@ApplicationScoped
public class ExportService {

    @PersistenceContext(unitName = "IdeaBoardPU")
    private EntityManager em;

    private static final DateTimeFormatter DATE_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");

    public byte[] exportIdeasToCsv() {
        List<Idea> ideas = em.createQuery("SELECT i FROM Idea i ORDER BY i.createdAt DESC", Idea.class)
                .getResultList();

        StringBuilder csv = new StringBuilder();
        csv.append("ID,Title,Description,Category,Status,Progress,Author,Likes,Comments,Created At\n");

        for (Idea idea : ideas) {
            csv.append(idea.getId()).append(",");
            csv.append(escapeCsv(idea.getTitle())).append(",");
            csv.append(escapeCsv(idea.getDescription())).append(",");
            csv.append(escapeCsv(idea.getCategory())).append(",");
            csv.append(idea.getStatus().name()).append(",");
            csv.append(idea.getProgressPercentage()).append("%,");
            csv.append(escapeCsv(idea.getAuthor().getUsername())).append(",");
            csv.append(idea.getLikeCount()).append(",");
            csv.append(idea.getCommentCount()).append(",");
            csv.append(idea.getCreatedAt().format(DATE_FORMAT)).append("\n");
        }

        return csv.toString().getBytes();
    }

    public byte[] exportStatisticsToCsv() {
        StringBuilder csv = new StringBuilder();
        csv.append("Metric,Value\n");

        // Total ideas
        Long totalIdeas = em.createQuery("SELECT COUNT(i) FROM Idea i", Long.class).getSingleResult();
        csv.append("Total Ideas,").append(totalIdeas).append("\n");

        // Ideas by status
        for (IdeaStatus status : IdeaStatus.values()) {
            Long count = em.createQuery("SELECT COUNT(i) FROM Idea i WHERE i.status = :status", Long.class)
                    .setParameter("status", status)
                    .getSingleResult();
            csv.append("Ideas - ").append(status.name()).append(",").append(count).append("\n");
        }

        // Total users
        Long totalUsers = em.createQuery("SELECT COUNT(u) FROM User u", Long.class).getSingleResult();
        csv.append("Total Users,").append(totalUsers).append("\n");

        // Total likes
        Long totalLikes = em.createQuery("SELECT COUNT(l) FROM Like l", Long.class).getSingleResult();
        csv.append("Total Likes,").append(totalLikes).append("\n");

        // Total comments
        Long totalComments = em.createQuery("SELECT COUNT(c) FROM Comment c", Long.class).getSingleResult();
        csv.append("Total Comments,").append(totalComments).append("\n");

        // Ideas by category
        @SuppressWarnings("unchecked")
        List<Object[]> categoryStats = em.createQuery(
                "SELECT i.category, COUNT(i) FROM Idea i GROUP BY i.category ORDER BY COUNT(i) DESC")
                .getResultList();
        for (Object[] row : categoryStats) {
            csv.append("Category - ").append(row[0]).append(",").append(row[1]).append("\n");
        }

        return csv.toString().getBytes();
    }

    public byte[] exportStatisticsToPdf() throws IOException {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        PdfWriter writer = new PdfWriter(baos);
        PdfDocument pdf = new PdfDocument(writer);
        Document document = new Document(pdf);

        PdfFont boldFont = PdfFontFactory.createFont(StandardFonts.HELVETICA_BOLD);
        PdfFont regularFont = PdfFontFactory.createFont(StandardFonts.HELVETICA);

        // Title
        Paragraph title = new Paragraph("GFOS IdeaBoard - Statistics Report")
                .setFont(boldFont)
                .setFontSize(20)
                .setTextAlignment(TextAlignment.CENTER)
                .setMarginBottom(20);
        document.add(title);

        // Generation date
        Paragraph date = new Paragraph("Generated: " + LocalDateTime.now().format(DATE_FORMAT))
                .setFont(regularFont)
                .setFontSize(10)
                .setTextAlignment(TextAlignment.RIGHT)
                .setMarginBottom(20);
        document.add(date);

        // Overview section
        document.add(new Paragraph("Overview").setFont(boldFont).setFontSize(14).setMarginTop(10));

        Long totalIdeas = em.createQuery("SELECT COUNT(i) FROM Idea i", Long.class).getSingleResult();
        Long totalUsers = em.createQuery("SELECT COUNT(u) FROM User u", Long.class).getSingleResult();
        Long totalLikes = em.createQuery("SELECT COUNT(l) FROM Like l", Long.class).getSingleResult();
        Long totalComments = em.createQuery("SELECT COUNT(c) FROM Comment c", Long.class).getSingleResult();

        Table overviewTable = new Table(UnitValue.createPercentArray(new float[]{50, 50}))
                .setWidth(UnitValue.createPercentValue(100));
        addTableRow(overviewTable, "Total Ideas", String.valueOf(totalIdeas), regularFont);
        addTableRow(overviewTable, "Total Users", String.valueOf(totalUsers), regularFont);
        addTableRow(overviewTable, "Total Likes", String.valueOf(totalLikes), regularFont);
        addTableRow(overviewTable, "Total Comments", String.valueOf(totalComments), regularFont);
        document.add(overviewTable);

        // Ideas by Status
        document.add(new Paragraph("Ideas by Status").setFont(boldFont).setFontSize(14).setMarginTop(20));

        Table statusTable = new Table(UnitValue.createPercentArray(new float[]{60, 40}))
                .setWidth(UnitValue.createPercentValue(100));
        addTableHeader(statusTable, "Status", "Count", boldFont);

        for (IdeaStatus status : IdeaStatus.values()) {
            Long count = em.createQuery("SELECT COUNT(i) FROM Idea i WHERE i.status = :status", Long.class)
                    .setParameter("status", status)
                    .getSingleResult();
            addTableRow(statusTable, status.name(), String.valueOf(count), regularFont);
        }
        document.add(statusTable);

        // Ideas by Category
        document.add(new Paragraph("Ideas by Category").setFont(boldFont).setFontSize(14).setMarginTop(20));

        @SuppressWarnings("unchecked")
        List<Object[]> categoryStats = em.createQuery(
                "SELECT i.category, COUNT(i) FROM Idea i GROUP BY i.category ORDER BY COUNT(i) DESC")
                .getResultList();

        Table categoryTable = new Table(UnitValue.createPercentArray(new float[]{60, 40}))
                .setWidth(UnitValue.createPercentValue(100));
        addTableHeader(categoryTable, "Category", "Count", boldFont);

        for (Object[] row : categoryStats) {
            addTableRow(categoryTable, String.valueOf(row[0]), String.valueOf(row[1]), regularFont);
        }
        document.add(categoryTable);

        // Top Ideas
        document.add(new Paragraph("Top 5 Ideas by Likes").setFont(boldFont).setFontSize(14).setMarginTop(20));

        List<Idea> topIdeas = em.createQuery(
                "SELECT i FROM Idea i ORDER BY i.likeCount DESC", Idea.class)
                .setMaxResults(5)
                .getResultList();

        Table topIdeasTable = new Table(UnitValue.createPercentArray(new float[]{50, 25, 25}))
                .setWidth(UnitValue.createPercentValue(100));
        addTableHeader(topIdeasTable, "Title", "Author", "Likes", boldFont);

        for (Idea idea : topIdeas) {
            addTableRow(topIdeasTable,
                    truncate(idea.getTitle(), 40),
                    idea.getAuthor().getUsername(),
                    String.valueOf(idea.getLikeCount()),
                    regularFont);
        }
        document.add(topIdeasTable);

        document.close();
        return baos.toByteArray();
    }

    private void addTableHeader(Table table, String... headers) {
        try {
            PdfFont boldFont = PdfFontFactory.createFont(StandardFonts.HELVETICA_BOLD);
            for (String header : headers) {
                Cell cell = new Cell()
                        .add(new Paragraph(header).setFont(boldFont))
                        .setBackgroundColor(ColorConstants.LIGHT_GRAY);
                table.addHeaderCell(cell);
            }
        } catch (IOException e) {
            throw new RuntimeException("Failed to create font", e);
        }
    }

    private void addTableRow(Table table, String... values) {
        try {
            PdfFont regularFont = PdfFontFactory.createFont(StandardFonts.HELVETICA);
            for (String value : values) {
                table.addCell(new Cell().add(new Paragraph(value).setFont(regularFont)));
            }
        } catch (IOException e) {
            throw new RuntimeException("Failed to create font", e);
        }
    }

    private void addTableRow(Table table, String label, String value, PdfFont font) {
        table.addCell(new Cell().add(new Paragraph(label).setFont(font)));
        table.addCell(new Cell().add(new Paragraph(value).setFont(font)));
    }

    private String escapeCsv(String value) {
        if (value == null) return "";
        if (value.contains(",") || value.contains("\"") || value.contains("\n")) {
            return "\"" + value.replace("\"", "\"\"") + "\"";
        }
        return value;
    }

    public byte[] exportUsersToCsv() {
        List<User> users = em.createQuery("SELECT u FROM User u ORDER BY u.createdAt DESC", User.class)
                .getResultList();

        StringBuilder csv = new StringBuilder();
        csv.append("ID,Username,Email,First Name,Last Name,Role,XP Points,Level,Ideas Count,Likes Given,Comments,Active,Created At\n");

        for (User user : users) {
            Long ideasCount = em.createQuery("SELECT COUNT(i) FROM Idea i WHERE i.author.id = :userId", Long.class)
                    .setParameter("userId", user.getId())
                    .getSingleResult();
            Long likesGiven = em.createQuery("SELECT COUNT(l) FROM Like l WHERE l.user.id = :userId", Long.class)
                    .setParameter("userId", user.getId())
                    .getSingleResult();
            Long commentsCount = em.createQuery("SELECT COUNT(c) FROM Comment c WHERE c.author.id = :userId", Long.class)
                    .setParameter("userId", user.getId())
                    .getSingleResult();

            csv.append(user.getId()).append(",");
            csv.append(escapeCsv(user.getUsername())).append(",");
            csv.append(escapeCsv(user.getEmail())).append(",");
            csv.append(escapeCsv(user.getFirstName())).append(",");
            csv.append(escapeCsv(user.getLastName())).append(",");
            csv.append(user.getRole().name()).append(",");
            csv.append(user.getXpPoints()).append(",");
            csv.append(user.getLevel()).append(",");
            csv.append(ideasCount).append(",");
            csv.append(likesGiven).append(",");
            csv.append(commentsCount).append(",");
            csv.append(user.getIsActive()).append(",");
            csv.append(user.getCreatedAt().format(DATE_FORMAT)).append("\n");
        }

        return csv.toString().getBytes();
    }

    private String truncate(String value, int maxLength) {
        if (value == null) return "";
        if (value.length() <= maxLength) return value;
        return value.substring(0, maxLength - 3) + "...";
    }
}
